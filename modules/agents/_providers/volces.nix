{
  name = "Volcengine Coding Plan";
  secret = "volcengine-codingplan-api-key";
  enable = false;
  defaultModel = "glm_5_3_flash";
  endpoints = {
    anthropic = "https://ark.cn-beijing.volces.com/api/coding";
    openai = "https://ark.cn-beijing.volces.com/api/coding/v3";
  };
  agents = {
    claudeCode = { };
    codex = {
      profile = "codex-volce";
      reasoningSummaries = true;
    };
    omp = { };
    pi.defaultModel = "glm_5_3";
  };
  models = {
    glm_5_3 = {
      id = "glm-5.3";
      displayName = "GLM 5.3";
      contextWindow = 1048576;
      input = [ "text" ];
      thinking = {
        efforts = [
          "low"
          "medium"
          "high"
        ];
        default = "medium";
      };
      claudeBehavesAs = "claude-opus-5-5";
    };
    glm_5_3_flash = {
      id = "glm-5.3-flash";
      displayName = "GLM 5.3 Flash";
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
