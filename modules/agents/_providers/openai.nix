{
  name = "OpenAI";
  secret = "openai-api-key";
  defaultModel = "gpt_6_1_sol";
  endpoints.openai = "https://api.openai.com/v1";
  models = {
    gpt_6_1_sol = {
      id = "gpt-6.1-sol";
      displayName = "GPT-6.1-Sol";
      description = "Latest workhorse model for coding and everyday work.";
      contextWindow = 272000;
      maxOutputTokens = 128000;
      input = [
        "text"
        "image"
      ];
      thinking = {
        efforts = [
          "low"
          "medium"
          "high"
          "xhigh"
          "max"
          "ultra"
        ];
        default = "low";
      };
      claudeBehavesAs = "claude-sonnet-5";
      codexPriority = 1;
      codexSupportsOriginalImageDetail = true;
    };
    gpt_6_astra = {
      id = "gpt-6-astra";
      displayName = "GPT-6-Astra";
      description = "Frontier intelligence for the most demanding work.";
      contextWindow = 272000;
      maxOutputTokens = 128000;
      input = [
        "text"
        "image"
      ];
      thinking = {
        efforts = [
          "low"
          "medium"
          "high"
          "xhigh"
          "max"
          "ultra"
        ];
        default = "low";
      };
      claudeBehavesAs = "claude-opus-5-5";
      codexPriority = 2;
      codexSupportsOriginalImageDetail = true;
    };
    gpt_6_luna = {
      id = "gpt-6-luna";
      displayName = "GPT-6-Luna";
      description = "Fast and affordable model for easier tasks.";
      contextWindow = 272000;
      maxOutputTokens = 128000;
      input = [
        "text"
        "image"
      ];
      thinking = {
        efforts = [
          "low"
          "medium"
          "high"
          "xhigh"
          "max"
        ];
        default = "medium";
      };
      claudeBehavesAs = "claude-sonnet-5";
      codexPriority = 4;
      codexSupportsOriginalImageDetail = true;
    };
  };
}
