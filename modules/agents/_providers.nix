{ config, lib }:
let
  providers = {
    qwen = {
      name = "Qwen Token Plan";
      secret = "qwen-tokenplan-api-key";
      endpoints = {
        anthropic = "https://token-plan.maas.qianwenaiapi.com/apps/anthropic";
        responses = "https://token-plan.maas.qianwenaiapi.com/compatible-mode/v1";
      };
      agents = {
        claudeCode = {
          enable = true;
          smallModel = "qwen3_8_flash";
        };
        codex = {
          enable = true;
          profile = "codex-qwen";
          providerName = "qwen-token-plan";
          defaultModel = "qwen3_8_max";
          reasoningEffort = true;
        };
        omp = {
          enable = true;
          endpoint = "anthropic";
          defaultModel = "qwen3_8_max";
        };
        pi = {
          enable = true;
          endpoint = "anthropic";
          defaultModel = "qwen3_8_max";
        };
      };
      models = {
        qwen3_8_max = {
          id = "qwen3.8-max";
          displayName = "Qwen3.8 Max";
          contextWindow = 983616;
          input = [
            "text"
            "image"
          ];
          thinking = {
            efforts = [
              "low"
              "medium"
              "xhigh"
            ];
            default = "xhigh";
          };
          codexCatalog = {
            priority = 1;
            supports_image_detail_original = true;
            supports_parallel_tool_calls = false;
          };
        };
        qwen3_8_flash = {
          id = "qwen3.8-flash";
          displayName = "Qwen3.8 Flash";
          contextWindow = 983616;
          input = [
            "text"
            "image"
          ];
          thinking = {
            efforts = [
              "low"
              "medium"
              "xhigh"
            ];
            default = "xhigh";
          };
          codexCatalog = {
            priority = 2;
            supports_image_detail_original = true;
            supports_parallel_tool_calls = false;
          };
        };
        qwen3_7_max = {
          id = "qwen3.7-max";
          displayName = "Qwen3.7 Max";
          contextWindow = 1000000;
          input = [ "text" ];
          thinking = {
            efforts = [
              "low"
              "medium"
              "high"
              "xhigh"
            ];
            default = "high";
          };
          codexCatalog = {
            priority = 3;
            supports_parallel_tool_calls = false;
          };
        };
        qwen3_7_plus = {
          id = "qwen3.7-plus";
          displayName = "Qwen3.7 Plus";
          contextWindow = 1000000;
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
            ];
            default = "high";
          };
          codexCatalog = {
            priority = 4;
            supports_image_detail_original = true;
            supports_parallel_tool_calls = false;
          };
        };
        glm_5_3 = {
          id = "glm-5.3";
          displayName = "GLM 5.3";
          contextWindow = 1000000;
          input = [ "text" ];
          thinking = {
            efforts = [
              "low"
              "medium"
              "high"
              "xhigh"
            ];
            default = "high";
          };
          codexCatalog = {
            priority = 6;
            supports_parallel_tool_calls = false;
          };
        };
        glm_5_2 = {
          id = "glm-5.2";
          displayName = "GLM 5.2";
          contextWindow = 1000000;
          input = [ "text" ];
          thinking = {
            efforts = [
              "low"
              "medium"
              "high"
              "xhigh"
            ];
            default = "high";
          };
          codexCatalog = {
            priority = 7;
            supports_parallel_tool_calls = false;
          };
        };
        ds_v4_1flash = {
          id = "deepseek-v4.1-flash";
          displayName = "DeepSeek-V4.1-Flash";
          contextWindow = 1000000;
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
            ];
            default = "high";
          };
          codexCatalog = {
            priority = 8;
            supports_image_detail_original = true;
            supports_parallel_tool_calls = false;
          };
        };
      };
    };
    senseaudio = {
      name = "SenseAudio Token Plan";
      secret = "senseaudio-tokenplan-api-key";
      endpoints = {
        anthropic = "https://api.senseaudio.cn";
        responses = "https://api.senseaudio.cn/v1";
      };
      agents = {
        claudeCode = {
          enable = true;
          smallModel = "ds_v4flash";
        };
        codex = {
          enable = true;
          profile = "codex-senseaudio";
          providerName = "senseaudio-token-plan";
          defaultModel = "ds_v4flash";
        };
        omp = {
          enable = true;
          endpoint = "anthropic";
          defaultModel = "ds_v4flash";
        };
        pi = {
          enable = true;
          endpoint = "anthropic";
          defaultModel = "ds_v4flash";
        };
      };
      models = {
        qwen3_8_27b = {
          id = "qwen3.8-27b";
          anthropicId = "qwen3.8-27b[1m]";
          displayName = "Qwen3.8-27B";
          description = "Qwen 3.8 27B Dense Model.";
          contextWindow = 1048576;
          input = [
            "text"
            "image"
          ];
          thinking = {
            efforts = [
              "low"
              "high"
              "xhigh"
            ];
            default = "high";
          };
        };
        ds_v4flash = {
          id = "deepseek-v4-flash-0731";
          anthropicId = "deepseek-v4-flash-0731[1m]";
          displayName = "DeepSeek-V4-Flash";
          description = "Latest frontier agentic coding model.";
          contextWindow = 1048576;
          input = [ "text" ];
          thinking = {
            efforts = [
              "low"
              "high"
              "max"
            ];
            default = "max";
          };
        };
        glm_5_2 = {
          id = "glm-5.2";
          anthropicId = "glm-5.2[1m]";
          displayName = "GLM 5.2";
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
        };
        glm_5_3_flash = {
          id = "glm-5.3-flash";
          anthropicId = "glm-5.3-flash[1m]";
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
          codexCatalog = {
            supports_image_detail_original = true;
          };
        };
      };
    };
    volces = {
      name = "Volcengine Coding Plan";
      secret = "volcengine-codingplan-api-key";
      endpoints = {
        anthropic = "https://ark.cn-beijing.volces.com/api/coding";
        responses = "https://ark.cn-beijing.volces.com/api/coding/v3";
      };
      agents = {
        claudeCode = {
          enable = false;
          smallModel = "glm_5_3_flash";
        };
        codex = {
          enable = false;
          profile = "codex-volce";
          providerName = "volcengine-coding-plan";
          defaultModel = "glm_5_3_flash";
          reasoningSummaries = true;
        };
        omp = {
          enable = false;
          endpoint = "anthropic";
          defaultModel = "glm_5_3_flash";
        };
        pi = {
          enable = false;
          endpoint = "anthropic";
          defaultModel = "glm_5_3";
        };
      };
      models = {
        glm_5_3 = {
          id = "glm-5.3";
          anthropicId = "glm-5.3[1m]";
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
        };
        glm_5_3_flash = {
          id = "glm-5.3-flash";
          anthropicId = "glm-5.3-flash[1m]";
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
          codexCatalog = {
            supports_image_detail_original = true;
          };
        };
      };
    };

    deepseek = {
      name = "DeepSeek";
      secret = "deepseek-api-key";
      endpoints = {
        openai = "https://api.deepseek.com";
        responses = "https://api.deepseek.com/";
        anthropic = "https://api.deepseek.com/anthropic";
        balance = "https://api.deepseek.com/user/balance";
      };
      agents = {
        claudeCode = {
          enable = true;
          smallModel = "ds_v4flash";
          effortLevel = "max";
        };
        codex = {
          enable = true;
          profile = "codex-ds";
          providerName = "deepseek";
          defaultModel = "ds_v4flash";
          reasoningEffort = true;
          disableWebSearch = true;
        };
        omp = {
          enable = true;
          endpoint = "anthropic";
        };
        reasonix = {
          enable = true;
          apiKeyEnv = "DEEPSEEK_API_KEY";
          providerName = "deepseek-flash";
          defaultModel = "ds_v4flash";
        };
      };
      models = {
        ds_v4flash = {
          id = "deepseek-flash";
          anthropicId = "deepseek-flash[1m]";
          displayName = "DeepSeek-Flash";
          description = "Latest frontier agentic coding model with image input.";
          contextWindow = 1048576;
          input = [
            "text"
            "image"
          ];
          maxOutputTokens = 384000;
          thinking = {
            efforts = [
              "low"
              "high"
              "max"
            ];
            default = "high";
          };
          codexCatalog = {
            priority = 1;
            supports_image_detail_original = true;
          };
        };
        ds_v4pro = {
          id = "deepseek-v4-pro";
          anthropicId = "deepseek-v4-pro[1m]";
          displayName = "DeepSeek-V4-Pro";
          description = "Most capable frontier agentic coding model.";
          contextWindow = 1048576;
          input = [ "text" ];
          maxOutputTokens = 384000;
          thinking = {
            efforts = [
              "low"
              "high"
              "max"
            ];
            default = "high";
          };
          codexCatalog = {
            priority = 2;
            supports_search_tool = false;
          };
        };
      };
    };

    gpu = {
      name = "GPU";
      secret = "gpu-api-key";
      endpoints = {
        openai = "http://172.18.36.44:8000/v1";
        responses = "http://172.18.36.44:8000/v1";
      };
      agents = {
        codex = {
          enable = true;
          profile = "codex-gpu";
          providerName = "codex-gpu";
          defaultModel = "qwen3_8_27b";
        };
        omp = {
          enable = true;
          endpoint = "openai";
        };
        pi = {
          enable = true;
          endpoint = "openai";
        };
      };
      models = {
        qwen3_8_27b = {
          id = "qwen3.8-27b";
          displayName = "Qwen3.8 27B";
          contextWindow = 240000;
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
          codexCatalog = {
            supports_image_detail_original = true;
          };
        };
      };
    };

    stepfun = {
      name = "StepFun Step Plan";
      secret = "stepfun-plan-api-key";
      endpoints = {
        anthropic = "https://api.stepfun.com/step_plan";
        openai = "https://api.stepfun.com/step_plan/v1";
        responses = "https://api.stepfun.com/step_plan/v1";
      };
      agents = {
        claudeCode = {
          enable = true;
          smallModel = "step_3_7_flash";
        };
        codex = {
          enable = true;
          profile = "codex-stepfun";
          providerName = "stepfun-step-plan";
          defaultModel = "step_5_preview";
          disableWebSearch = true;
        };
        omp = {
          enable = true;
          endpoint = "anthropic";
          defaultModel = "step_5_preview";
        };
        pi = {
          enable = true;
          endpoint = "anthropic";
          defaultModel = "step_5_preview";
        };
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
        };
      };
    };
  };

  # Wire protocol spoken by each `endpoints` key; agent modules pick the entry
  # named by their `endpoint` field.
  endpointApis = {
    anthropic = "anthropic-messages";
    openai = "openai-completions";
  };

  selectProviders =
    agent: lib.filterAttrs (_name: provider: provider.agents.${agent}.enable or false) providers;

  # Every provider authenticates through an agenix secret named after
  # `secrets/<secret>.age`.
  ageSecrets =
    selected:
    lib.listToAttrs (
      lib.map (
        provider:
        lib.nameValuePair provider.secret {
          file = ../../secrets + "/${provider.secret}.age";
        }
      ) (lib.attrValues selected)
    );
in
{
  inherit
    endpointApis
    selectProviders
    ageSecrets
    ;
}
