{
  name = "DeepSeek";
  secret = "deepseek-api-key";
  defaultModel = "ds_v4flash";
  endpoints = {
    anthropic = "https://api.deepseek.com/anthropic";
    balance = "https://api.deepseek.com/user/balance";
    openai = "https://api.deepseek.com";
  };
  agents = {
    claudeCode.effortLevel = "max";
    claudeDesktop = {
      default = true;
      profileId = "00000000-0000-4000-8000-00000000d335";
      models = [
        "ds_v4flash"
        "ds_v4pro"
      ];
    };
    codex = {
      disableWebSearch = true;
      profile = "codex-ds";
    };
    omp = { };
    pi.default = true;
    reasonix.default = true;
  };
  models = {
    ds_v4flash = {
      id = "deepseek-flash";
      displayName = "DeepSeek-V4.1-Flash";
      description = "Latest frontier agentic coding model with image input.";
      contextWindow = 1048576;
      maxOutputTokens = 384000;
      input = [
        "text"
        "image"
      ];
      thinking = {
        efforts = [
          "low"
          "high"
          "max"
        ];
        default = "high";
      };
      claudeBehavesAs = "claude-sonnet-5";
      codexPriority = 1;
      codexSupportsOriginalImageDetail = true;
    };
    ds_v4pro = {
      id = "deepseek-v4-pro";
      displayName = "DeepSeek-V4-Pro";
      description = "Most capable frontier agentic coding model.";
      contextWindow = 1048576;
      maxOutputTokens = 384000;
      input = [ "text" ];
      thinking = {
        efforts = [
          "low"
          "high"
          "max"
        ];
        default = "high";
      };
      claudeBehavesAs = "claude-opus-5-5";
      codexPriority = 2;
      codexSupportsSearchTool = false;
    };
  };
}
