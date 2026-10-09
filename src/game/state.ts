export type Ruling = "AMEND" | "DESTROY" | "REFER" | null;

export type GameState = {
  employeeId: string;
  standing: number;
  curiosity: number;
  caseId: string;
  viewedEvidence: string[];
  ruling: Ruling;
};

const key = "gfp-games-state-v1";

export function initialState(): GameState {
  return {
    employeeId: "RC-88214",
    standing: 2,
    curiosity: 0,
    caseId: "RC-41-773",
    viewedEvidence: [],
    ruling: null
  };
}

export function loadState(): GameState {
  try {
    const raw = localStorage.getItem(key);
    return raw ? { ...initialState(), ...JSON.parse(raw) } : initialState();
  } catch {
    return initialState();
  }
}

export function saveState(state: GameState) {
  localStorage.setItem(key, JSON.stringify(state));
}

export function resetState() {
  localStorage.removeItem(key);
}
