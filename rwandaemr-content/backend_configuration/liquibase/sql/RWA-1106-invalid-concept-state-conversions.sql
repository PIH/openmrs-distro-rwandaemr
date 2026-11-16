-- RWA-1106: delete concept state conversions whose concept, program workflow or workflow state doesn't exist,
-- or whose state belongs to a different workflow.
DELETE x FROM concept_state_conversion x
  LEFT JOIN program_workflow w ON w.program_workflow_id = x.program_workflow_id
  LEFT JOIN program_workflow_state s ON s.program_workflow_state_id = x.program_workflow_state_id
  LEFT JOIN concept c ON c.concept_id = x.concept_id
 WHERE w.program_workflow_id IS NULL OR s.program_workflow_state_id IS NULL OR c.concept_id IS NULL
    OR s.program_workflow_id <> w.program_workflow_id;
