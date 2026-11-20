import copy
import os
from pathlib import Path
import runpy
import unittest

UPDATER = os.environ.get("AGENT_MODELS_UPDATER") or (
    Path(__file__).resolve().parents[3] / "scripts/update-agent-models.py"
)
updater = runpy.run_path(str(UPDATER))
select_models = updater["select_models"]


class UpdateModelsTests(unittest.TestCase):
    def setUp(self):
        self.facts = {
            "name": "Example",
            "reasoning": True,
            "tool_call": True,
            "modalities": {"input": ["text", "image", "pdf"], "output": ["text"]},
            "limit": {"context": 1050000, "input": 922000, "output": 128000},
        }
        self.providers = {
            "custom": {
                "modelsDevProvider": "source-provider",
                "models": ["api-id"],
            }
        }

    def test_only_model_facts_are_imported(self):
        source = {"source-provider": {"models": {"api-id": self.facts | {
            "id": "api-id", "api": "https://example.invalid", "cost": {"input": 1},
            "reasoning_options": [{"type": "effort", "values": ["high"]}],
        }}}}
        expected = {
            "custom": {
                "api-id": self.facts | {
                    "reasoning_options": [{"type": "effort", "values": ["high"]}],
                }
            }
        }
        self.assertEqual(select_models(source, self.providers), expected)

    def test_preserves_model_limits_and_modalities(self):
        source = {"source-provider": {"models": {"api-id": copy.deepcopy(self.facts)}}}
        self.assertEqual(select_models(source, self.providers)["custom"]["api-id"], self.facts)
        self.assertEqual(source["source-provider"]["models"]["api-id"], self.facts)

    def test_selected_models_are_imported_per_connection(self):
        providers = self.providers | {"other": self.providers["custom"]}
        source = {"source-provider": {"models": {"api-id": self.facts}}}
        self.assertEqual(list(select_models(source, providers)), ["custom", "other"])

    def test_local_only_connections_are_not_fetched(self):
        providers = {"custom": {
            "modelsDevProvider": "source-provider",
            "models": ["local/model"],
        }}
        self.assertEqual(select_models({}, providers), {})

    def test_missing_model_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "source-provider/api-id"):
            select_models({"source-provider": {"models": {}}}, self.providers)

    def test_unselected_models_are_not_imported(self):
        source = {"source-provider": {"models": {
            "api-id": self.facts,
            "other-id": self.facts,
        }}}
        self.assertEqual(list(select_models(source, self.providers)["custom"]), ["api-id"])

    def test_result_is_sorted(self):
        providers = {"custom": {
            "modelsDevProvider": "source-provider",
            "models": ["z", "a"],
        }}
        source = {"source-provider": {"models": {"z": self.facts, "a": self.facts}}}
        self.assertEqual(list(select_models(source, providers)["custom"]), ["z", "a"])


if __name__ == "__main__":
    unittest.main()
