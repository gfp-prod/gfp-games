import { useEffect, useState } from "react";
import { GameState, loadState, resetState, saveState } from "./game/state";

const opening = [
  "The elevator stops on B-14.",
  "The doors open onto a long room of green filing cabinets. Fluorescent lights hum overhead.",
  "It is 7:58 AM. Your shift begins in two minutes.",
  "Your terminal is already on.",
  "",
  "A file waits on the screen.",
  "",
  "CASE RC-41-773",
  "Structure 118-C was demolished in Year 31.",
  "A municipal photograph dated Year 47 shows the building still standing."
];

const entries: Record<string, string[]> = {
  look: [
    "Rows of desks disappear beneath fluorescent light.",
    "No one speaks. Somewhere behind you, a stamp strikes paper at regular intervals.",
    "On your desk: the terminal, a paper cup, and your Red Record card."
  ],
  file: [
    "MUNICIPAL PHOTOGRAPH — 118-C",
    "The building stands intact.",
    "On the eastern wall is a mural of a man seated at a table.",
    "His right hand is hidden beneath it.",
    "",
    "Reverse inscription: YEAR 47."
  ],
  search: [
    "ARCHIVE SEARCH: STRUCTURE 118-C",
    "One additional result.",
    "",
    "REED, DANTE — Untitled interior. Oil and ash on board.",
    "Artist record unavailable."
  ]
};

function App() {
  const [state, setState] = useState<GameState>(() => loadState());
  const [history, setHistory] = useState<string[]>(opening);
  const [command, setCommand] = useState("");

  useEffect(() => saveState(state), [state]);

  function submit(e: React.FormEvent) {
    e.preventDefault();
    const raw = command.trim();
    if (!raw) return;
    const cmd = raw.toLowerCase();
    let reply: string[];

    if (["look", "look around"].includes(cmd)) reply = entries.look;
    else if (["file", "open file", "inspect file", "photo", "inspect photo"].includes(cmd)) reply = entries.file;
    else if (cmd.startsWith("search")) {
      reply = entries.search;
      setState(s => ({ ...s, curiosity: s.curiosity + 1 }));
    } else if (cmd === "amend") {
      reply = ["You amend the photograph's date to YEAR 31.", "CASE RESOLVED.", "Your standing improves."];
      setState(s => ({ ...s, ruling: "AMEND", standing: s.standing + 1 }));
    } else if (cmd === "destroy") {
      reply = ["You mark the photograph for destruction.", "CASE RESOLVED.", "Contradiction removed."];
      setState(s => ({ ...s, ruling: "DESTROY", standing: s.standing + 2 }));
    } else if (cmd === "refer") {
      reply = ["REFER TO: DEPARTMENT OF RECLAIMED CULTURAL MATERIALS", "", "A moment passes.", "ACCESS DENIED.", "", "Someone at the desk behind you stops stamping."];
      setState(s => ({ ...s, ruling: "REFER", standing: s.standing - 1, curiosity: s.curiosity + 2 }));
    } else if (cmd === "help") {
      reply = ["Try: LOOK, OPEN FILE, SEARCH 118-C, AMEND, DESTROY, REFER."];
    } else {
      reply = ["The terminal does not recognize that instruction.", "Type HELP if you require assistance."];
    }

    setHistory(h => [...h, "", "> " + raw.toUpperCase(), ...reply]);
    setCommand("");
  }

  function restart() {
    resetState();
    setState(loadState());
    setHistory(opening);
    setCommand("");
  }

  return (
    <main className="shell">
      <header className="masthead">
        <div>
          <p className="eyebrow">RED COMPANY // HISTORICAL RECTIFICATION</p>
          <h1>Terminal 14</h1>
        </div>
        <div className="employee"><span>{state.employeeId}</span></div>
      </header>

      <article className="reader terminal">
        <div className="story">
          {history.map((line, i) => <p key={i}>{line || "\u00a0"}</p>)}
        </div>

        {!state.ruling ? (
          <form onSubmit={submit} className="command-line">
            <span>&gt;</span>
            <input
              autoFocus
              value={command}
              onChange={e => setCommand(e.target.value)}
              aria-label="Command"
              autoComplete="off"
              placeholder="type a command"
            />
          </form>
        ) : (
          <div className="result">
            <button onClick={restart}>BEGIN AGAIN</button>
          </div>
        )}
      </article>
    </main>
  );
}

export default App;
