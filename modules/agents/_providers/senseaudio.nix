{
  name = "SenseAudio Token Plan";
  secret = "senseaudio-tokenplan-api-key";
  defaultModel = "ds_v4_1flash";
  endpoints = {
    anthropic = "https://api.senseaudio.cn";
    openai = "https://api.senseaudio.cn/v1";
  };
  agents = {
    claudeCode = { };
    codex = { };
    omp.default = true;
    pi.default = true;
  };
  models = {
    ds_v4_1flash = {
      id = "deepseek-v4.1-flash";
      displayName = "DeepSeek-V4.1-Flash";
      description = "Latest frontier agentic coding model with image input.";
      contextWindow = 1048576;
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
        default = "max";
      };
      claudeBehavesAs = "claude-sonnet-5";
      codexSupportsOriginalImageDetail = true;
    };
    glm_5_3_flash = {
      id = "glm-5.3-flash";
      displayName = "GLM-5.3-Flash";
      contextWindow = 1048576;
      input = [
        "text"
        "image"
      ];
      thinking = {
        efforts = [
          "low"
          "medium"
          "high"
        ];
        default = "high";
      };
      claudeBehavesAs = "claude-sonnet-5";
      codexSupportsOriginalImageDetail = true;
    };
  };
}
