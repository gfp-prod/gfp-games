import { useEffect, useMemo, useState } from "react";
import { firstCase } from "./game/cases";
import { GameState, loadState, resetState, saveState } from "./game/state";

function App() {
  const [state, setState] = useState<GameState>(() => loadState());
  const [selected, setSelected] = useState(firstCase.evidence[0].id);
  const [notice, setNotice] = useState("ASSIGNMENT READY");

  useEffect(() => {
    saveState(state);
  }, [state]);

  const selectedEvidence = useMemo(
    () => firstCase.evidence.find((item) => item.id === selected)!,
    [selected]
  );

  function viewEvidence(id: string) {
    setSelected(id);
    setState((current) =>
      current.viewedEvidence.includes(id)
        ? current
        : {
            ...current,
            viewedEvidence: [...current.viewedEvidence, id],
            curiosity: current.curiosity + (id === "memo" ? 1 : 0)
          }
    );
  }

  function rule(ruling: "AMEND" | "DESTROY" | "REFER") {
    const viewedAll = state.viewedEvidence.length === firstCase.evidence.length;
    let standing = state.standing;
    let curiosity = state.curiosity;

    if (ruling === "AMEND") standing += 1;
    if (ruling === "DESTROY") standing += 2;
    if (ruling === "REFER") {
      curiosity += 2;
      standing -= 1;
    }

    setState((current) => ({ ...current, ruling, standing, curiosity }));

    if (!viewedAll) {
      setNotice("RULING ACCEPTED — INCOMPLETE REVIEW NOTED");
    } else if (ruling === "REFER") {
      setNotice("REFERRED: DEPARTMENT OF RECLAIMED CULTURAL MATERIALS");
    } else if (ruling === "DESTROY") {
      setNotice("DESTRUCTION ORDER LOGGED");
    } else {
      setNotice("AUTHORIZED RECORD AMENDED");
    }
  }

  function restart() {
    resetState();
    const fresh = loadState();
    setState(fresh);
    setSelected(firstCase.evidence[0].id);
    setNotice("ASSIGNMENT READY");
  }

  return (
    <main className="shell">
      <header className="masthead">
        <div>
          <p className="eyebrow">RED COMPANY // OFFICE OF HISTORICAL RECTIFICATION</p>
          <h1>Records Terminal</h1>
        </div>
        <div className="employee">
          <span>EMPLOYEE {state.employeeId}</span>
          <span>STANDING {state.standing}</span>
          <span>CURIOSITY {state.curiosity}</span>
        </div>
      </header>

      <section className="notice">{notice}</section>

      <section className="case-grid">
        <aside className="case-panel">
          <p className="eyebrow">CASE {firstCase.id}</p>
          <h2>{firstCase.title}</h2>
          <p>{firstCase.directive}</p>

          <div className="authorized">
            <span>AUTHORIZED RECORD</span>
            <p>{firstCase.authorizedRecord}</p>
          </div>

          <nav className="evidence-list" aria-label="Evidence">
            {firstCase.evidence.map((item) => (
              <button
                key={item.id}
                onClick={() => viewEvidence(item.id)}
                className={selected === item.id ? "active" : ""}
              >
                <small>{item.classification}</small>
                <strong>{item.label}</strong>
                <span>
                  {state.viewedEvidence.includes(item.id) ? "REVIEWED" : "UNREAD"}
                </span>
              </button>
            ))}
          </nav>
        </aside>

        <article className="reader">
          <div className="reader-meta">
            <span>{selectedEvidence.classification}</span>
            <span>{selectedEvidence.id.toUpperCase()}</span>
          </div>
          <h3>{selectedEvidence.label}</h3>
          <p>{selectedEvidence.body}</p>

          <div className="actions">
            <button disabled={!!state.ruling} onClick={() => rule("AMEND")}>
              AMEND
              <small>Correct evidence to match Authorized Record.</small>
            </button>
            <button disabled={!!state.ruling} onClick={() => rule("DESTROY")}>
              DESTROY
              <small>Remove contradictory material.</small>
            </button>
            <button disabled={!!state.ruling} onClick={() => rule("REFER")}>
              REFER
              <small>Escalate anomaly for specialist review.</small>
            </button>
          </div>

          {state.ruling && (
            <div className="result">
              <p>FINAL RULING: <strong>{state.ruling}</strong></p>
              <p>
                Your decision has been entered into your Red Record. Further
                assignments will be issued according to performance and standing.
              </p>
              <button onClick={restart}>RESET PROTOTYPE</button>
            </div>
          )}
        </article>
      </section>
    </main>
  );
}

export default App;
