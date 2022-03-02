
#include "../Scripts/library/utils.hxx"

string name="Time Aligner";
string description="Detects phase shift and realigns input signals";


array<double> inputParameters(3);
array<string> inputParametersNames = { "Detection", "Mono", "Align"};
array<int> inputParametersSteps = {2, 2, 2};
array<string> inputParametersEnums = {"Play;Detect", "Off;Mono", "Off;Align"}; // which units to use
array<double> inputParametersMin = { 0, 0, 0}; // min values
array<double> inputParametersMax = { 1, 1, 1}; // max values
array<double> inputParametersDefault = { 0, 0, 0}; // default values

// OUTPUT STRINGS
array<int> outputStringsMaxLengths = { 100 };
array<string> outputStringsNames = { "Phase", "Polarity" };
array<string>  outputStrings(outputStringsNames.length);

// PARAMETER VALUES
int writeIndex = 0;
int currentIndex;
int readIndex;
array<array<double>> buffers(audioInputsCount);
int bufferSize = 2048;
int shift = 0;
int mask;
bool makeMono;
double mono;
bool alignFlag;
bool detectP;

// CONSTANTS
//const uint minTransientTime = uint(msToSamples(200.));//this is where you can set the buffer size in ms
const uint phaseAlignBufferSize = uint(hzToSamples(100.));//sometimes increasing these was better accuracy

Align align;
enum AlignState { Off, WaitForCollect, Collecting, Aligning };

double hzToSamples(double hz) { return sampleRate / hz; }


bool initialize() {
	// if not a stereo channel
	if (audioInputsCount != 2) {
		print("Stereo channels only!"); // print to log file
		return false; // stops processing a script
	}
	else {
		// create buffer with 2^x size
		int lengthPow2 = KittyDSP::Utils::nextPowerOfTwo(bufferSize);
		mask = lengthPow2;
		for (uint channel = 0, count = buffers.length;channel < count;channel++)
		{
			buffers[channel].resize(lengthPow2);
		}

		return true; // proceeds with processing a script
	}

}

void reset()
{
	// reset buffers with silence
	for (uint channel = 0, count = buffers.length;channel < count;channel++)
	{
		// init with zeros
		for (uint i = 0;i < buffers[channel].length;i++)
		{
			buffers[channel][i] = 0;
		}
	}

	writeIndex = 0;
}

void processBlock(BlockData& data)
{

	// either detect new correlation values (phase and polarity)
	// or delay the signal by current measurements
	if (detectP)
		align.processBlock(data);

	if (alignFlag)
		shift = align.sampleDelay;
	else
		shift = 0;


	for (uint channel = 0, count = audioInputsCount; channel < count; channel++)
	{

		for (uint i = 0; i < data.samples[channel].length; i++)
		{

			//Write to buffer
			currentIndex = (writeIndex + i) % mask;
			buffers[channel][currentIndex] = data.samples[channel][i];

			//Read From buffer
			if (shift < 0 and channel == 0) { //Shifting left channel backwards in time

				readIndex = (currentIndex + shift + mask) % mask;
				data.samples[channel][i] = buffers[channel][readIndex];
			}
			if (channel == 1) {
				if (shift > 0) { //Shifting right channel backwards in time

					readIndex = (currentIndex - shift + mask) % mask;
					data.samples[channel][i] = buffers[channel][readIndex];
				}

				if (makeMono) {

					//Combine left and right channels to Mono
					mono = (data.samples[0][i] + data.samples[1][i]) / 2;
					data.samples[0][i] = mono;
					data.samples[1][i] = mono;
				}

			}
			
		}
	}

	writeIndex = (writeIndex + data.samples[1].length) % mask;
}



void updateInputParameters()
{

	makeMono =  inputParameters[1] > .5;
	
	alignFlag = inputParameters[2] > .5;

	bool newDetectP = inputParameters[0] > .5;
	if (detectP != newDetectP)
	{
		detectP = newDetectP;
		if (detectP)
			align.initDetection();
	}

}



class Align
{
	Align()
	{
		for (uint ch = 0; ch < buffer.length; ++ch)
			buffer[ch].length = phaseAlignBufferSize;
		wHead = 0;
		state = AlignState::Off;
		sampleDelay = 0;
	}
	void initDetection() // this is called before a new detection starts to prepare the align-object's state.
	{
		if (state != AlignState::Off) return;
		state = AlignState::WaitForCollect;
		wHead = 0;
	}
	void processBlock(BlockData& data)
	{
		switch (state)
		{
		case AlignState::WaitForCollect: processBlockWaitForCollect(data); break;
		case AlignState::Collecting: processBlockCollecting(data); break;
		default: return;
		}
	}
	void processBlockWaitForCollect(BlockData& data)
	{
		state = AlignState::Collecting;
		processBlockCollecting(data, 0);
	}
	void processBlockCollecting(BlockData& data, uint startSample = 0)
	{
		for (uint s = startSample; s < data.samplesToProcess; ++s)
		{
			if (wHead < phaseAlignBufferSize)
			{
				for (uint ch = 0; ch < buffer.length; ++ch)
					buffer[ch][wHead] = data.samples[ch][s];
				++wHead;
			}
			else
			{
				state = AlignState::Aligning;
				
				align();
				return;
			}
		}
	}

	void align()
	{
		array<double> correlation(phaseAlignBufferSize);
		for (uint i = 0; i < phaseAlignBufferSize; ++i)
		{
			correlation[i] = 0.;
			for (uint j = 0; j < phaseAlignBufferSize; ++j)
			{
				uint k = i + j;
				if (k >= phaseAlignBufferSize)
					k -= phaseAlignBufferSize;
				correlation[i] += buffer[0][j] * buffer[1][k];
			}
		}

		int polarity = 1;
		int idx = 0;
		double max = 0.;
		for (uint i = 0; i < phaseAlignBufferSize; ++i)
		{
			int pol = 1;
			if (correlation[i] < 0.)
				pol = -1;
			double absCorrelation = correlation[i] * pol;
			if (max < absCorrelation)
			{
				max = absCorrelation;
				idx = int(i);
				polarity = pol;
			}
		}
		int delayValue = idx;

		sampleDelay = delayValue *-1;

		outputStrings[0] = delayValue;
		outputStrings[1] = polarity;

		state = AlignState::Off;
	}

	array<array<double>> buffer(audioInputsCount + auxAudioInputsCount);
	int state;
	uint wHead;
	int sampleDelay;
}