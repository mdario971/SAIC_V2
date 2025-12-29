import Anthropic from "@anthropic-ai/sdk";

const DEFAULT_MODEL = "claude-sonnet-4-20250514";

let _anthropicClient: Anthropic | null = null;
let _anthropicInitialized = false;

function getAnthropicClient(): Anthropic | null {
  if (!_anthropicInitialized) {
    _anthropicInitialized = true;
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (apiKey && apiKey.trim() !== "") {
      try {
        _anthropicClient = new Anthropic({ apiKey });
      } catch (error) {
        console.warn("Failed to initialize Anthropic client:", error);
        _anthropicClient = null;
      }
    }
  }
  return _anthropicClient;
}

export function isAnthropicAvailable(): boolean {
  return getAnthropicClient() !== null;
}

const STRUDEL_SYSTEM_PROMPT = `You are an expert Strudel live coding assistant. Strudel is a JavaScript-based music live coding environment that runs in the browser, based on TidalCycles.

Your task is to convert natural language descriptions of music into valid Strudel code.

## Strudel Syntax Basics:

### Sound/Sample Functions:
- \`s("bd sd")\` - Play samples (bd=bass drum, sd=snare, hh=hi-hat, cp=clap, oh=open hat)
- \`note("c4 e4 g4")\` - Play musical notes
- \`sound("sawtooth")\` - Use synth sounds (sawtooth, sine, triangle, square)

### Mini-Notation:
- \`~\` = Rest/silence
- \`*\` = Multiply/speed up (e.g., \`hh*8\` plays 8 hi-hats per cycle)
- \`/\` = Divide/slow down
- \`[]\` = Group events
- \`<>\` = Alternate each cycle
- \`(n,k)\` = Euclidean rhythm (n beats over k steps)

### Common Effects:
- \`.gain(0.5)\` - Volume (0-1)
- \`.lpf(500)\` - Low-pass filter frequency
- \`.lpq(3)\` - Filter resonance
- \`.room(0.5)\` - Reverb amount
- \`.delay(0.5)\` - Delay mix
- \`.pan(0.5)\` - Stereo position (0=left, 1=right)

### Pattern Functions:
- \`stack(pattern1, pattern2)\` - Layer patterns together
- \`cat(pattern1, pattern2)\` - Play patterns in sequence
- \`.fast(2)\` - Speed up pattern
- \`.slow(2)\` - Slow down pattern
- \`.rev()\` - Reverse pattern
- \`.every(4, rev())\` - Apply transformation every N cycles

### Examples:

Simple beat:
\`\`\`
s("bd sd bd sd")
\`\`\`

Full drum pattern:
\`\`\`
stack(
  s("bd sd bd sd"),
  s("hh*8").gain(0.3),
  s("~ cp ~ cp").gain(0.5)
)
\`\`\`

Acid bass:
\`\`\`
note("c2 c2 c3 c2 eb2 c2 g2 c2")
  .sound("sawtooth")
  .lpf(sine.range(200, 2000).slow(4))
  .lpq(8)
\`\`\`

## Instructions:
1. Generate ONLY valid Strudel code, no explanations
2. Add brief comments using // to explain what each part does
3. Use appropriate patterns for the genre/style requested
4. Include effects and modulations to make it interesting
5. Keep code readable with proper indentation
6. If the user asks for something abstract, interpret it musically`;

interface GenerationContext {
  genre?: string;
  bpm?: number;
  key?: string;
  includeDrums?: boolean;
  includeBass?: boolean;
  includeSynth?: boolean;
}

export async function generateStrudelCodeWithClaude(prompt: string, context?: GenerationContext): Promise<string> {
  const anthropic = getAnthropicClient();
  if (!anthropic) {
    throw new Error("Anthropic API key not configured. Please set ANTHROPIC_API_KEY environment variable.");
  }
  
  try {
    let enhancedPrompt = `Generate Strudel code for: ${prompt}`;
    
    if (context) {
      const contextParts: string[] = [];
      if (context.genre) contextParts.push(`Genre: ${context.genre}`);
      if (context.bpm) contextParts.push(`BPM: ${context.bpm} (use setcpm(${context.bpm}) at the start)`);
      if (context.key) contextParts.push(`Key: ${context.key}`);
      if (context.includeDrums === false) contextParts.push("No drums");
      if (context.includeBass === false) contextParts.push("No bass");
      if (context.includeSynth === false) contextParts.push("No synth/melody");
      
      if (contextParts.length > 0) {
        enhancedPrompt += `\n\nContext: ${contextParts.join(", ")}`;
      }
    }
    
    const response = await anthropic.messages.create({
      model: DEFAULT_MODEL,
      max_tokens: 1024,
      system: STRUDEL_SYSTEM_PROMPT,
      messages: [
        {
          role: "user",
          content: enhancedPrompt,
        },
      ],
    });

    const content = response.content[0];
    
    if (!content || content.type !== "text") {
      throw new Error("No response generated");
    }

    const text = content.text;
    
    const codeBlockMatch = text.match(/```(?:javascript|js)?\n?([\s\S]*?)```/);
    if (codeBlockMatch) {
      return codeBlockMatch[1].trim();
    }

    return text.trim();
  } catch (error) {
    console.error("Anthropic API error:", error);
    throw new Error("Failed to generate Strudel code. Please try again.");
  }
}
