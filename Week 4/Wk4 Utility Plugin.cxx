/** \file default.cxx
*   Default script, with no processing function.
*   Will simply do nothing (full audio and MIDI bypass) but show its description.
*/
string name="Utility";
string description="Week 4 Sound tool";

array<double> inputParameters(3);
array<string> inputParametersNames = { "Gain", "Invert", "Mono"};
array<string> inputParametersEnums = { "", "Off;On", "Off;On"};
array<int> inputParametersSteps = { -1, 2, 2};
array<string> inputParametersUnits = { "dB", "", "" }; // which units to use
array<double> inputParametersMin = { -20, 0, 0}; // min values
array<double> inputParametersMax = { 20, 1, 1}; // max values
array<double> inputParametersDefault = { 0, 1, 0}; // default values

array<string> outputParametersNames(audioInputsCount);
array<string> outputParametersUnits(audioInputsCount);
array<double> outputParameters(audioInputsCount);
array<double> outputParametersMin(audioInputsCount);
array<double> outputParametersMax(audioInputsCount);

//we'll keep our gain values here (set default to 1)
double gain = 1;
double norm = 1;
double mono = 0;
double div = 1;

// meter decay
const double decay = 1 - exp(-log(10) / (sampleRate*.3));

// levels array
array<double>   levels(audioInputsCount);


void initialize()
{
	if (audioInputsCount > 0)
		div = 1 / double(audioInputsCount);

	// initialize output parameters properties
	if (audioInputsCount == 1)
		outputParametersNames[0] = "Level";
	else if (audioInputsCount == 2)
	{
		outputParametersNames[0] = "Left";
		outputParametersNames[1] = "Right";
	}
	else
	{
		for (uint i = 0;i < outputParametersNames.length;i++)
		{
			outputParametersNames[i] = "Level Ch" + (i + 1);
		}
	}
	for (uint i = 0;i < audioInputsCount;i++)
	{
		outputParametersUnits[i] = "dB";
		outputParametersMin[i] = -60;
		outputParametersMax[i] = 0;
	}
}


// this is main audio processing function
void processSample(array<double>& ioSample) {
	
	// Gain+Invert
	for (uint i = 0;i < audioInputsCount;i++) {
		ioSample[i] *= gain;
		ioSample[i] *= norm;
	}

	//Mono
	if (mono!=0){
		// compute average
		double sum = 0;
		for (uint i = 0;i < audioInputsCount;i++)
		{
			sum += ioSample[i];
		}
		sum *= div;

		// copy to outputs
		for (uint i = 0;i < audioOutputsCount;i++)
		{
			ioSample[i] = sum;
		}
	}
	
	// Level meters 
	for (uint i = 0;i < audioInputsCount;i++) {

		double value = abs(ioSample[i]);
		double level = levels[i];
		if (value > level)
			level = value;
		else
			level += decay * (value - level);
		levels[i] = level;
	}
	
}

// this function is called when inputParameters change
void updateInputParameters() {
	// convert dB values to gain values
	// formula: gain=10^(gaindB/20)
	gain = pow(10, inputParameters[0] / 20);
	norm = -2 * inputParameters[1] + 1;
	mono = inputParameters[2];
}

int getTailSize()
{
	// 1000 milliseconds to let meters reach -60 dB
	return int(1 * sampleRate);
}

void reset()
{
	// reset levels to 0
	for (uint i = 0;i < levels.length;i++)
	{
		levels[i] = 0;
	}
}

void computeOutputData()
{
	for (uint i = 0;i < audioInputsCount;i++)
	{
		if (levels[i] > pow(10, -3)) // -60 dB limit
			outputParameters[i] = 20 * log10(levels[i]);
		else
			outputParameters[i] = -60;
	}
}