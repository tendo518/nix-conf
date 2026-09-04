{ config, lib }:
let
  providers = {
    aliyun = {
      name = "Aliyun Coding Plan";
      secret = {
        name = "aliyun-codingplan-api-key";
        file = ../../secrets/aliyun-codingplan-api-key.age;
        path = config.age.secrets.aliyun-codingplan-api-key.path;
      };
      endpoints.anthropic = "https://coding.dashscope.aliyuncs.com/apps/anthropic";
      agents.claudeCode = {
        enable = false;
        smallModel = "qwen3_5_plus";
      };
      models = {
        qwen3_max = {
          id = "qwen3-max-2026-01-23";
          displayName = "Qwen3 Max";
          input = [ "text" ];
        };
        qwen3_6_plus = {
          id = "qwen3.6-plus";
          displayName = "Qwen3.6 Plus";
          input = [ "text" ];
        };
        glm_5 = {
          id = "glm-5";
          displayName = "GLM 5";
          input = [ "text" ];
        };
      };
    };
    senseaudio = {
      name = "SenseAudio Token Plan";
      secret = {
        name = "senseaudio-tokenplan-api-key";
        file = ../../secrets/senseaudio-tokenplan-api-key.age;
        path = config.age.secrets.senseaudio-tokenplan-api-key.path;
      };
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
          api = "anthropic-messages";
          endpoint = "anthropic";
          defaultModel = "ds_v4flash";
        };
        pi = {
          enable = true;
          api = "anthropic-messages";
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
          supportsImageDetailOriginal = true;
          thinking = {
            efforts = [
              "low"
              "medium"
              "high"
            ];
            default = "high";
          };
        };
      };
    };
    volces = {
      name = "Volcengine Coding Plan";
      secret = {
        name = "volcengine-codingplan-api-key";
        file = ../../secrets/volcengine-codingplan-api-key.age;
        path = config.age.secrets.volcengine-codingplan-api-key.path;
      };
      endpoints = {
        anthropic = "https://ark.cn-beijing.volces.com/api/coding";
        responses = "https://ark.cn-beijing.volces.com/api/coding/v3";
      };
      agents = {
        claudeCode = {
          enable = true;
          smallModel = "glm_5_3_flash";
        };
        codex = {
          enable = true;
          profile = "codex-volce";
          providerName = "volcengine-coding-plan";
          defaultModel = "glm_5_3_flash";
          reasoningSummaries = true;
        };
        omp = {
          enable = true;
          api = "anthropic-messages";
          endpoint = "anthropic";
          defaultModel = "glm_5_3_flash";
        };
        pi = {
          enable = true;
          api = "anthropic-messages";
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
          supportsImageDetailOriginal = true;
          thinking = {
            efforts = [
              "low"
              "medium"
              "high"
            ];
            default = "high";
          };
        };
      };
    };

    deepseek = {
      name = "DeepSeek";
      secret = {
        name = "deepseek-api-key";
        file = ../../secrets/deepseek-api-key.age;
        path = config.age.secrets.deepseek-api-key.path;
      };
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
        };
        omp = {
          enable = true;
          api = "anthropic-messages";
          endpoint = "anthropic";
        };
        pi.enable = false;
        reasonix = {
          enable = true;
          apiKeyEnv = "DEEPSEEK_API_KEY";
          providerName = "deepseek-flash";
          defaultModel = "ds_v4flash";
        };
      };
      models = {
        ds_v4flash = {
          id = "deepseek-v4-flash";
          anthropicId = "deepseek-v4-flash[1m]";
          displayName = "DeepSeek-V4-Flash";
          description = "Latest frontier agentic coding model.";
          priority = 1;
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
        };
        ds_v4pro = {
          id = "deepseek-v4-pro";
          anthropicId = "deepseek-v4-pro[1m]";
          displayName = "DeepSeek-V4-Pro";
          description = "Most capable frontier agentic coding model.";
          priority = 2;
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
        };
        ds_v4flash_vision_exp = {
          id = "deepseek-v4-flash-vision-exp";
          anthropicId = "deepseek-v4-flash-vision-exp[1m]";
          displayName = "DeepSeek-V4-Flash-Vision";
          description = "Latest frontier agentic coding model with image input.";
          priority = 3;
          contextWindow = 1048576;
          input = [
            "text"
            "image"
          ];
          supportsImageDetailOriginal = true;
          maxOutputTokens = 384000;
          thinking = {
            efforts = [
              "low"
              "high"
              "max"
            ];
            default = "high";
          };
        };
      };
    };

    gpu = {
      name = "GPU";
      apiKey = "8b964310965445819bfd028144ba7cb34676c7f33c97c73966050fb59e903bd5";
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
          api = "openai-completions";
          endpoint = "openai";
        };
        pi = {
          enable = true;
          api = "openai-completions";
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
          supportsImageDetailOriginal = true;
          thinking = {
            efforts = [
              "low"
              "medium"
              "high"
            ];
            default = "high";
          };
        };
      };
    };
  };

  selectProviders =
    agent: lib.filterAttrs (_name: provider: provider.agents.${agent}.enable or false) providers;

  ageSecrets =
    selected:
    lib.listToAttrs (
      lib.map (provider: lib.nameValuePair provider.secret.name { inherit (provider.secret) file; }) (
        lib.filter (provider: provider ? secret) (lib.attrValues selected)
      )
    );
in
{
  inherit
    providers
    selectProviders
    ageSecrets
    ;
}
