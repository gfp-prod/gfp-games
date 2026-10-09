export type EvidenceItem = {
  id: string;
  label: string;
  body: string;
  classification: string;
};

export type CaseFile = {
  id: string;
  title: string;
  directive: string;
  authorizedRecord: string;
  evidence: EvidenceItem[];
};

export const firstCase: CaseFile = {
  id: "RC-41-773",
  title: "Property Record Reconciliation",
  directive:
    "Resolve discrepancies between surviving pre-Reclamation materials and the Authorized Record. Curiosity beyond task scope may affect standing.",
  authorizedRecord:
    "Structure 118-C, formerly located in Fulton Administrative District, was condemned and demolished in Year 31 of the Consolidation. No cultural material of value was recovered.",
  evidence: [
    {
      id: "photo",
      label: "Municipal Photograph",
      classification: "ROUTINE / VISUAL",
      body:
        "A damaged black-and-white photograph shows Structure 118-C standing intact. A handwritten date on the reverse corresponds to Year 47 of the Consolidation. A mural is visible on the eastern wall: a seated man, his right hand obscured beneath the table."
    },
    {
      id: "catalog",
      label: "Recovered Museum Index",
      classification: "CULTURAL / OBSOLETE",
      body:
        "Fragmentary catalog entry: 'Reed, Dante — Untitled interior, oil and ash on board.' Provenance note references an address matching Structure 118-C. Artist record unavailable."
    },
    {
      id: "memo",
      label: "Security Memorandum",
      classification: "RESTRICTED / PARTIAL",
      body:
        "Only one line survives the redaction process: 'Transfer any confirmed DEAD HAND MATERIAL without local review.' The phrase DEAD HAND MATERIAL is not defined in your current employee handbook."
    }
  ]
};
