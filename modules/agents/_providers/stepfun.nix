{
  name = "StepFun Step Plan";
  secret = "stepfun-plan-api-key";
  defaultModel = "step_5_preview";
  endpoints = {
    anthropic = "https://api.stepfun.com/step_plan";
    openai = "https://api.stepfun.com/step_plan/v1";
  };
  agents = {
    claudeCode.smallModel = "step_3_7_flash";
    codex.disableWebSearch = true;
    omp = { };
    pi = { };
  };
  models = {
    step_5_preview = {
      id = "step-5-preview";
      displayName = "Step 5 Preview";
      description = "Flagship model for coding and knowledge work, with a 1M-token context window.";
      contextWindow = 1048576;
      maxOutputTokens = 1048576;
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
      claudeBehavesAs = "claude-opus-5-5";
    };
    step_3_7_flash = {
      id = "step-3.7-flash";
      displayName = "Step 3.7 Flash";
      description = "Flagship multimodal reasoning model for agent and coding tasks.";
      contextWindow = 262144;
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
    };
    step_router_v1 = {
      id = "step-router-v1";
      displayName = "Step Router V1";
      description = "Routes each request between deepseek-v4-pro and step-3.7-flash.";
      contextWindow = 262144;
      maxOutputTokens = 250000;
      input = [ "text" ];
      thinking = {
        efforts = [
          "low"
          "high"
        ];
        default = "high";
      };
      claudeBehavesAs = "claude-sonnet-5";
    };
  };
}
