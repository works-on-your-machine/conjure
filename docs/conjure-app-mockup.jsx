import { useState } from "react";

const FONTS = "https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,600;1,400&family=DM+Sans:wght@400;500&display=swap";
const C = {
  bg: "#1e1a2e", bgDeep: "#161323", surface: "#2d2540", surfaceLight: "#3a3255",
  gold: "#c4935a", goldLight: "#e8d5b5", goldDim: "#a38050",
  goldGlow: "rgba(196,147,90,0.15)", goldGlowStrong: "rgba(196,147,90,0.3)",
  text: "#e8e0d4", textMuted: "#9a8e80", textDim: "#6a6058", plum: "#7b6b8a",
  border: "rgba(196,147,90,0.12)", borderHover: "rgba(196,147,90,0.25)", danger: "#c0392b",
};
const serif = "'Cormorant Garamond', Georgia, serif";
const sans = "'DM Sans', system-ui, sans-serif";

// Data
const allGrimoires = [
  { id: "pirate", name: "Pirate Broadcast", desc: "VHS static. CRT monitors with scan lines. Punk zine meets late-night public access TV. Taped-up paper, hand-drawn red circles, glitch effects.\n\nColors: Black backgrounds, phosphor green, hot pink and cyan bursts. Warm cream for paper.\n\nTypography: Monospace terminal, hand-scrawled annotations, bold stamped headlines.\n\nEra: 1985 meets 2025. Analog warmth through digital decay.", usedIn: 3 },
  { id: "bauhaus", name: "Bauhaus Clean", desc: "Geometric Bauhaus-inspired. Clean cream backgrounds with bold navy, gold, and rust color blocks. Watercolor-style illustrations mixed with sharp geometric shapes.\n\nTypography: Strong serif headlines, clean sans body. Editorial, confident.\n\nMood: The intelligent warmth of a well-designed annual report crossed with an art exhibition catalog.", usedIn: 1 },
  { id: "vapor", name: "Vapor Archive", desc: "Neon gradients on deep purple. Retro-future Japanese city pop aesthetic. Chrome text, sunset gradients, grid floors stretching to infinity.\n\nColors: Hot pink, electric cyan, deep indigo, chrome silver.\n\nTypography: Bold condensed sans, italic accents, glowing outlines.\n\nEra: 1988 as imagined from 2030.", usedIn: 0 },
];

const allProjects = [
  { id: "p1", name: "Talking Shit About AI Agents", grimoire: "pirate", slides: 20, selected: 20, lastModified: "2 days ago", status: "complete" },
  { id: "p2", name: "The People You Don't Have Yet", grimoire: "bauhaus", slides: 15, selected: 12, lastModified: "1 week ago", status: "in-progress" },
  { id: "p3", name: "Prompt Object Oriented Programming", grimoire: "pirate", slides: 18, selected: 18, lastModified: "3 weeks ago", status: "complete" },
];

const defaultSlides = [
  { id: 1, title: "Title card", desc: "Talk title with dramatic presentation. The name of the talk in large type with supporting visual energy." },
  { id: 2, title: "The problem", desc: "Show a breaking news broadcast frame. Display the core tension — what everyone thinks vs what's actually happening." },
  { id: 3, title: "The hidden truth", desc: "The reframe. The thing nobody is seeing. Visual should feel like a revelation — something being uncovered." },
  { id: 4, title: "Historical context", desc: "Take us back in time. Show the origin of the idea. Green terminal aesthetic, time travel feeling." },
  { id: 5, title: "The mechanism", desc: "How it works under the hood. Diagram-like but stylized. X-ray or blueprint feeling." },
  { id: 6, title: "Live demo", desc: "Special bulletin / broadcast interrupt. 'Please stand by' energy. Something is about to happen." },
  { id: 7, title: "Implications", desc: "What this means for the audience. Side-by-side comparison of old way vs new way." },
  { id: 8, title: "Call to action", desc: "Closing slide. Contact info, links. 'Stay tuned' energy. Color test bars." },
];

function grad(si, vi, tid) {
  const t = { pirate: [["#0a0a0a","#1a472a","#00ff41"],["#0a0a0a","#2d1b4e","#ff00ff"],["#0a0a0a","#4a1a1a","#ff3333"],["#1a1a2e","#16213e","#0f3460"],["#0a0a0a","#1a3a2a","#00ffcc"],["#111","#2a1a00","#ff8800"],["#0a0a0a","#3a1a3a","#ff69b4"],["#0a0a0a","#1a2a3a","#4488ff"]], bauhaus: [["#f5f0e8","#c4a35a","#2d3561"],["#f5f0e8","#d4622b","#1a1a2e"],["#f5f0e8","#2d3561","#c4a35a"],["#eee8d5","#b85c38","#2d3561"],["#f5f0e8","#1a1a2e","#d4622b"],["#f0ebe0","#3d5561","#c49050"],["#f5f0e8","#8a3a2a","#2d4561"],["#eee8d5","#c4935a","#4a2a5a"]], vapor: [["#2b1055","#d946ef","#0ea5e9"],["#1e1b4b","#f472b6","#06b6d4"],["#2b1055","#a855f7","#22d3ee"],["#1e1b4b","#e879f9","#38bdf8"],["#2b1055","#c084fc","#0ea5e9"],["#1e1b4b","#d946ef","#22d3ee"],["#2b1055","#f472b6","#38bdf8"],["#1e1b4b","#a855f7","#06b6d4"]] };
  const c = (t[tid]||t.pirate)[(si+vi)%8]; const a = (si*47+vi*73)%360;
  return `linear-gradient(${a}deg, ${c[0]}, ${c[1]}, ${c[2]})`;
}

// Shared components
function Btn({ children, variant="default", onClick, style={}, disabled }) {
  const base = { fontFamily: sans, fontSize: "13px", border: "none", borderRadius: "6px", cursor: disabled?"default":"pointer", transition: "all 0.15s", opacity: disabled?0.4:1, ...style };
  const v = { default: { background: C.surface, color: C.textMuted, padding: "8px 16px", border: `1px solid ${C.border}` }, gold: { background: C.gold, color: C.bgDeep, padding: "8px 20px", fontWeight: 500 }, ghost: { background: "transparent", color: C.textMuted, padding: "8px 12px" }, danger: { background: "transparent", color: C.danger, padding: "8px 16px", border: "1px solid rgba(192,57,43,0.3)" } };
  return <button style={{ ...base, ...v[variant] }} onClick={onClick} disabled={disabled}>{children}</button>;
}
function TextArea({ value, onChange, placeholder, rows=4, style={} }) {
  return <textarea value={value} onChange={e=>onChange(e.target.value)} placeholder={placeholder} rows={rows} style={{ width:"100%", background:C.surface, color:C.text, border:`1px solid ${C.border}`, borderRadius:"6px", padding:"12px", fontFamily:sans, fontSize:"13px", lineHeight:1.6, resize:"vertical", outline:"none", boxSizing:"border-box", ...style }} />;
}
function Input({ value, onChange, placeholder, style={} }) {
  return <input value={value} onChange={e=>onChange(e.target.value)} placeholder={placeholder} style={{ width:"100%", background:C.surface, color:C.text, border:`1px solid ${C.border}`, borderRadius:"6px", padding:"10px 12px", fontFamily:sans, fontSize:"13px", outline:"none", boxSizing:"border-box", ...style }} />;
}
function Label({ children }) {
  return <div style={{ fontSize:"11px", textTransform:"uppercase", letterSpacing:"0.08em", color:C.textDim, marginBottom:"6px", fontFamily:sans }}>{children}</div>;
}
function Variation({ si, vi, tid, isSelected, onClick }) {
  return <div onClick={onClick} style={{ aspectRatio:"16/9", borderRadius:"6px", overflow:"hidden", cursor:"pointer", position:"relative", background:grad(si,vi,tid), transition:"all 0.2s", border:isSelected?`2px solid ${C.gold}`:`1px solid rgba(255,255,255,0.06)`, boxShadow:isSelected?`0 0 24px ${C.goldGlowStrong}`:"0 2px 8px rgba(0,0,0,0.3)", transform:isSelected?"scale(1.02)":"scale(1)" }}>
    {tid==="pirate" && <div style={{ position:"absolute", inset:0, background:"repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(0,0,0,0.12) 2px, rgba(0,0,0,0.12) 4px)", pointerEvents:"none" }} />}
    {isSelected && <div style={{ position:"absolute", top:"6px", right:"6px", width:"20px", height:"20px", borderRadius:"50%", background:C.gold, display:"flex", alignItems:"center", justifyContent:"center", fontSize:"11px", color:C.bgDeep, fontWeight:600 }}>✦</div>}
  </div>;
}

// Thumbnail mosaic for project cards
function ProjectMosaic({ grimId }) {
  return <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:"3px", borderRadius:"4px", overflow:"hidden" }}>
    {[0,1,2,3].map(i => <div key={i} style={{ aspectRatio:"16/9", background:grad(i,i*2,grimId) }} />)}
  </div>;
}

// Grimoire preview strip
function GrimoireStrip({ grimId }) {
  return <div style={{ display:"flex", gap:"3px", borderRadius:"4px", overflow:"hidden" }}>
    {[0,1,2,3,4].map(i => <div key={i} style={{ flex:1, aspectRatio:"16/9", background:grad(i,i,grimId) }} />)}
  </div>;
}

// ──────────────── HOME SCREEN ────────────────
function HomeScreen({ projects, grimoires, onOpenProject, onNewProject, onOpenGrimoires }) {
  return <div style={{ padding:"40px", maxWidth:"960px", margin:"0 auto" }}>
    <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:"32px" }}>
      <div>
        <h1 style={{ fontFamily:serif, fontSize:"32px", fontWeight:600, color:C.gold, margin:0 }}>Conjure</h1>
        <p style={{ fontSize:"13px", color:C.textDim, margin:"4px 0 0" }}>Your workshop</p>
      </div>
      <div style={{ display:"flex", gap:"10px" }}>
        <Btn onClick={onOpenGrimoires}>◈ Grimoire library</Btn>
        <Btn variant="gold" onClick={onNewProject}>✦ Conjure new project</Btn>
      </div>
    </div>

    {projects.length === 0 ? (
      <div style={{ textAlign:"center", padding:"80px 40px", border:`1px dashed ${C.border}`, borderRadius:"12px" }}>
        <div style={{ fontSize:"48px", marginBottom:"16px" }}>✦</div>
        <h2 style={{ fontFamily:serif, fontSize:"24px", color:C.goldLight, margin:"0 0 8px" }}>Your workshop is empty</h2>
        <p style={{ fontSize:"13px", color:C.textMuted, marginBottom:"24px", maxWidth:"400px", margin:"0 auto 24px" }}>Every presentation begins as a vision. Describe a vibe, conjure some slides, curate your favorites.</p>
        <div style={{ display:"flex", gap:"12px", justifyContent:"center" }}>
          <Btn variant="gold" onClick={onNewProject}>Start from scratch</Btn>
          <Btn onClick={onNewProject}>Start from an outline</Btn>
        </div>
      </div>
    ) : (
      <div style={{ display:"grid", gridTemplateColumns:"repeat(auto-fill, minmax(280px, 1fr))", gap:"16px" }}>
        {projects.map(p => {
          const grim = grimoires.find(g => g.id === p.grimoire);
          return <div key={p.id} onClick={() => onOpenProject(p)} style={{ background:C.surface, borderRadius:"10px", border:`1px solid ${C.border}`, padding:"16px", cursor:"pointer", transition:"all 0.15s" }}
            onMouseEnter={e => e.currentTarget.style.borderColor = C.borderHover}
            onMouseLeave={e => e.currentTarget.style.borderColor = C.border}>
            <ProjectMosaic grimId={p.grimoire} />
            <h3 style={{ fontFamily:serif, fontSize:"17px", fontWeight:600, color:C.goldLight, margin:"12px 0 4px" }}>{p.name}</h3>
            <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center" }}>
              <span style={{ fontSize:"11px", color:C.plum }}>◈ {grim?.name}</span>
              <span style={{ fontSize:"11px", color:C.textDim }}>{p.lastModified}</span>
            </div>
            <div style={{ marginTop:"8px", display:"flex", alignItems:"center", gap:"8px" }}>
              <div style={{ flex:1, height:"3px", background:C.bgDeep, borderRadius:"2px", overflow:"hidden" }}>
                <div style={{ width:`${(p.selected/p.slides)*100}%`, height:"100%", background:p.selected===p.slides?C.gold:C.plum, borderRadius:"2px", transition:"width 0.3s" }} />
              </div>
              <span style={{ fontSize:"11px", color:C.textDim }}>{p.selected}/{p.slides}</span>
            </div>
          </div>;
        })}
        {/* New project card */}
        <div onClick={onNewProject} style={{ borderRadius:"10px", border:`1px dashed ${C.border}`, padding:"16px", cursor:"pointer", display:"flex", flexDirection:"column", alignItems:"center", justifyContent:"center", minHeight:"180px", transition:"all 0.15s" }}
          onMouseEnter={e => e.currentTarget.style.borderColor = C.goldDim}
          onMouseLeave={e => e.currentTarget.style.borderColor = C.border}>
          <span style={{ fontSize:"28px", color:C.goldDim, marginBottom:"8px" }}>✦</span>
          <span style={{ fontSize:"13px", color:C.textDim }}>New project</span>
        </div>
      </div>
    )}
  </div>;
}

// ──────────────── GRIMOIRE LIBRARY ────────────────
function GrimoireLibrary({ grimoires, onBack, onCreateNew, onEdit }) {
  return <div style={{ padding:"40px", maxWidth:"960px", margin:"0 auto" }}>
    <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:"32px" }}>
      <div style={{ display:"flex", alignItems:"center", gap:"16px" }}>
        <button onClick={onBack} style={{ background:"none", border:"none", color:C.textMuted, cursor:"pointer", fontSize:"14px", fontFamily:sans }}>← Workshop</button>
        <div>
          <h1 style={{ fontFamily:serif, fontSize:"28px", fontWeight:600, color:C.gold, margin:0 }}>Grimoire Library</h1>
          <p style={{ fontSize:"13px", color:C.textDim, margin:"2px 0 0" }}>{grimoires.length} visual worlds</p>
        </div>
      </div>
      <Btn variant="gold" onClick={onCreateNew}>✦ Create new grimoire</Btn>
    </div>
    <div style={{ display:"grid", gridTemplateColumns:"repeat(auto-fill, minmax(300px, 1fr))", gap:"16px" }}>
      {grimoires.map(g => (
        <div key={g.id} onClick={() => onEdit(g)} style={{ background:C.surface, borderRadius:"10px", border:`1px solid ${C.border}`, padding:"16px", cursor:"pointer", transition:"all 0.15s" }}
          onMouseEnter={e => e.currentTarget.style.borderColor = C.borderHover}
          onMouseLeave={e => e.currentTarget.style.borderColor = C.border}>
          <GrimoireStrip grimId={g.id} />
          <h3 style={{ fontFamily:serif, fontSize:"17px", fontWeight:600, color:C.goldLight, margin:"12px 0 4px" }}>{g.name}</h3>
          <p style={{ fontSize:"12px", color:C.textMuted, lineHeight:1.5, margin:"0 0 10px", display:"-webkit-box", WebkitLineClamp:3, WebkitBoxOrient:"vertical", overflow:"hidden" }}>{g.desc}</p>
          <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center" }}>
            <span style={{ fontSize:"11px", color:C.textDim }}>Used in {g.usedIn} project{g.usedIn!==1?"s":""}</span>
            <div style={{ display:"flex", gap:"6px" }}>
              <Btn variant="ghost" style={{ fontSize:"11px", padding:"4px 8px" }}>Duplicate</Btn>
              <Btn variant="ghost" style={{ fontSize:"11px", padding:"4px 8px" }}>Edit</Btn>
            </div>
          </div>
        </div>
      ))}
    </div>
  </div>;
}

// ──────────────── NEW PROJECT FLOW ────────────────
function NewProjectFlow({ grimoires, onCancel, onComplete }) {
  const [step, setStep] = useState(0);
  const [name, setName] = useState("");
  const [grim, setGrim] = useState(null);
  const [startType, setStartType] = useState(null);

  const steps = ["Name your project", "Choose a grimoire", "How do you want to start?"];

  return <div style={{ padding:"40px", maxWidth:"640px", margin:"0 auto" }}>
    <button onClick={onCancel} style={{ background:"none", border:"none", color:C.textMuted, cursor:"pointer", fontSize:"14px", fontFamily:sans, marginBottom:"24px" }}>← Back to workshop</button>

    {/* Step indicator */}
    <div style={{ display:"flex", gap:"8px", marginBottom:"32px" }}>
      {steps.map((s, i) => <div key={i} style={{ display:"flex", alignItems:"center", gap:"8px" }}>
        <div style={{ width:"24px", height:"24px", borderRadius:"50%", display:"flex", alignItems:"center", justifyContent:"center", fontSize:"12px", fontFamily:sans, fontWeight:500, background:i<=step?C.gold:"transparent", color:i<=step?C.bgDeep:C.textDim, border:i<=step?"none":`1px solid ${C.border}` }}>{i+1}</div>
        <span style={{ fontSize:"12px", color:i===step?C.text:C.textDim, fontFamily:sans }}>{s}</span>
        {i < steps.length-1 && <div style={{ width:"24px", height:"1px", background:C.border }} />}
      </div>)}
    </div>

    {/* Step 0: Name */}
    {step === 0 && <div>
      <h2 style={{ fontFamily:serif, fontSize:"24px", fontWeight:600, color:C.goldLight, margin:"0 0 16px" }}>What's this presentation called?</h2>
      <Input value={name} onChange={setName} placeholder="e.g. RubyConf 2026 Keynote" style={{ fontSize:"18px", fontFamily:serif, padding:"14px 16px" }} />
      <div style={{ marginTop:"20px", display:"flex", justifyContent:"flex-end" }}>
        <Btn variant="gold" disabled={!name.trim()} onClick={() => setStep(1)}>Next →</Btn>
      </div>
    </div>}

    {/* Step 1: Grimoire */}
    {step === 1 && <div>
      <h2 style={{ fontFamily:serif, fontSize:"24px", fontWeight:600, color:C.goldLight, margin:"0 0 8px" }}>Choose a visual world</h2>
      <p style={{ fontSize:"13px", color:C.textMuted, margin:"0 0 20px" }}>Pick a grimoire from your library, or create a new one.</p>
      <div style={{ display:"flex", flexDirection:"column", gap:"10px" }}>
        {grimoires.map(g => <div key={g.id} onClick={() => setGrim(g.id)} style={{
          padding:"14px 16px", borderRadius:"8px", cursor:"pointer", transition:"all 0.15s",
          background:grim===g.id?C.goldGlow:C.surface,
          border:`1px solid ${grim===g.id?C.goldDim:C.border}`,
        }}>
          <GrimoireStrip grimId={g.id} />
          <div style={{ marginTop:"10px", display:"flex", justifyContent:"space-between", alignItems:"center" }}>
            <span style={{ fontSize:"14px", fontWeight:500, color:grim===g.id?C.gold:C.text, fontFamily:sans }}>{g.name}</span>
            {grim===g.id && <span style={{ fontSize:"11px", color:C.gold }}>✦ Selected</span>}
          </div>
          <p style={{ fontSize:"12px", color:C.textDim, margin:"4px 0 0", lineHeight:1.4, display:"-webkit-box", WebkitLineClamp:2, WebkitBoxOrient:"vertical", overflow:"hidden" }}>{g.desc}</p>
        </div>)}
        <div onClick={() => {}} style={{ padding:"14px 16px", borderRadius:"8px", cursor:"pointer", border:`1px dashed ${C.border}`, textAlign:"center" }}>
          <span style={{ fontSize:"13px", color:C.textDim }}>✦ Create a new grimoire</span>
        </div>
      </div>
      <div style={{ marginTop:"20px", display:"flex", justifyContent:"space-between" }}>
        <Btn onClick={() => setStep(0)}>← Back</Btn>
        <Btn variant="gold" disabled={!grim} onClick={() => setStep(2)}>Next →</Btn>
      </div>
    </div>}

    {/* Step 2: Starting point */}
    {step === 2 && <div>
      <h2 style={{ fontFamily:serif, fontSize:"24px", fontWeight:600, color:C.goldLight, margin:"0 0 8px" }}>How do you want to start?</h2>
      <p style={{ fontSize:"13px", color:C.textMuted, margin:"0 0 20px" }}>You can always add, remove, and edit slides later.</p>
      <div style={{ display:"flex", flexDirection:"column", gap:"10px" }}>
        {[
          { id:"blank", icon:"◇", title:"Blank slate", desc:"Start with an empty project and write each slide description yourself" },
          { id:"outline", icon:"✦", title:"Paste an outline", desc:"Paste your talk notes, bullet points, or brain dump and let AI break it into slides" },
          { id:"template", icon:"▣", title:"Use a template", desc:"Start from a pre-built structure: conference talk, pitch deck, lightning talk, workshop" },
        ].map(opt => <div key={opt.id} onClick={() => setStartType(opt.id)} style={{
          padding:"16px", borderRadius:"8px", cursor:"pointer", transition:"all 0.15s",
          background:startType===opt.id?C.goldGlow:C.surface,
          border:`1px solid ${startType===opt.id?C.goldDim:C.border}`,
          display:"flex", gap:"14px", alignItems:"flex-start",
        }}>
          <span style={{ fontSize:"18px", color:startType===opt.id?C.gold:C.textDim, marginTop:"2px" }}>{opt.icon}</span>
          <div>
            <div style={{ fontSize:"14px", fontWeight:500, color:startType===opt.id?C.gold:C.text, fontFamily:sans }}>{opt.title}</div>
            <div style={{ fontSize:"12px", color:C.textDim, marginTop:"2px" }}>{opt.desc}</div>
          </div>
        </div>)}
      </div>
      <div style={{ marginTop:"20px", display:"flex", justifyContent:"space-between" }}>
        <Btn onClick={() => setStep(1)}>← Back</Btn>
        <Btn variant="gold" disabled={!startType} onClick={() => onComplete({ name, grimoire:grim, startType })}>
          Create project →
        </Btn>
      </div>
    </div>}
  </div>;
}

// ──────────────── PROJECT WORKSPACE ────────────────
function Workspace({ project, grimoires, onBackToHome }) {
  const grim = grimoires.find(g => g.id === project.grimoire) || grimoires[0];
  const [view, setView] = useState("slides");
  const [slides, setSlides] = useState(defaultSlides);
  const [activeSlide, setActiveSlide] = useState(0);
  const [selected, setSelected] = useState({});
  const [variations] = useState(5);
  const [generating, setGenerating] = useState(false);
  const [generated, setGenerated] = useState(false);
  const [activeGrimoire, setActiveGrimoire] = useState(grim);
  const [showOutlineModal, setShowOutlineModal] = useState(false);
  const [outlineText, setOutlineText] = useState("");
  const [showThemeModal, setShowThemeModal] = useState(false);
  const [refineSlide, setRefineSlide] = useState(null);
  const [refinePrompt, setRefinePrompt] = useState("");
  const [newSlideTitle, setNewSlideTitle] = useState("");

  const handleGenerate = () => { setGenerating(true); setSelected({}); setTimeout(() => { setGenerating(false); setGenerated(true); setView("wall"); }, 1800); };

  const nav = [
    { id:"grimoire", label:"Grimoire", icon:"◈" },
    { id:"slides", label:"Incantations", icon:"◇" },
    { id:"wall", label:"Visions", icon:"◆", disabled:!generated },
    { id:"assembly", label:"Final cut", icon:"▣", disabled:!generated },
  ];

  return <div style={{ display:"flex", height:"100vh" }}>
    {/* Sidebar */}
    <div style={{ width:"200px", borderRight:`1px solid ${C.border}`, padding:"20px 0", flexShrink:0, display:"flex", flexDirection:"column" }}>
      <div style={{ padding:"0 16px 16px" }}>
        <button onClick={onBackToHome} style={{ background:"none", border:"none", color:C.textDim, cursor:"pointer", fontSize:"11px", fontFamily:sans, padding:0, marginBottom:"8px" }}>← Workshop</button>
        <div style={{ fontFamily:serif, fontSize:"15px", fontWeight:600, color:C.goldLight, lineHeight:1.3 }}>{project.name}</div>
        <div style={{ fontSize:"11px", color:C.plum, marginTop:"2px" }}>◈ {activeGrimoire.name}</div>
      </div>
      <div style={{ padding:"8px 12px", flex:1, borderTop:`1px solid ${C.border}` }}>
        {nav.map(n => <div key={n.id} onClick={() => !n.disabled && setView(n.id)} style={{
          padding:"10px 12px", borderRadius:"6px", cursor:n.disabled?"default":"pointer", marginBottom:"4px", transition:"all 0.15s", display:"flex", alignItems:"center", gap:"10px",
          background:view===n.id?C.goldGlow:"transparent", color:n.disabled?C.textDim:view===n.id?C.gold:C.textMuted, opacity:n.disabled?0.4:1,
        }}><span style={{ fontSize:"14px" }}>{n.icon}</span><span style={{ fontSize:"13px" }}>{n.label}</span></div>)}
      </div>
      <div style={{ padding:"16px 12px", borderTop:`1px solid ${C.border}` }}>
        <div style={{ fontSize:"11px", color:C.textDim, marginBottom:"8px", textAlign:"center" }}>{slides.length} slides × {variations} var ≈ ${(slides.length*variations*0.08).toFixed(2)}</div>
        <button onClick={handleGenerate} disabled={generating||slides.length===0} style={{
          width:"100%", padding:"12px", border:"none", borderRadius:"8px", cursor:generating?"wait":"pointer",
          fontFamily:serif, fontSize:"16px", fontWeight:600, letterSpacing:"0.04em",
          background:generating?C.goldGlow:`linear-gradient(135deg, ${C.gold}, ${C.goldDim})`,
          color:generating?C.gold:C.bgDeep, boxShadow:generating?"none":`0 4px 20px ${C.goldGlowStrong}`, transition:"all 0.3s",
        }}>{generating?"✦ Summoning...":generated?"✦ Re-conjure":"✦ Conjure"}</button>
      </div>
    </div>

    {/* Content */}
    <div style={{ flex:1, overflow:"auto" }}>

      {/* GRIMOIRE */}
      {view==="grimoire" && <div style={{ padding:"32px", maxWidth:"720px" }}>
        <h2 style={{ fontFamily:serif, fontSize:"28px", fontWeight:600, color:C.goldLight, margin:"0 0 4px" }}>Grimoire</h2>
        <p style={{ fontSize:"13px", color:C.textMuted, marginBottom:"24px" }}>The visual world for this project</p>
        <Label>Active grimoire</Label>
        <div style={{ display:"flex", gap:"8px", marginBottom:"16px", flexWrap:"wrap" }}>
          {grimoires.map(g => <div key={g.id} onClick={() => setActiveGrimoire(g)} style={{
            padding:"10px 16px", borderRadius:"8px", cursor:"pointer", flex:"1 1 140px",
            background:activeGrimoire.id===g.id?C.goldGlow:C.surface, border:`1px solid ${activeGrimoire.id===g.id?C.goldDim:C.border}`,
          }}><div style={{ fontSize:"13px", fontWeight:500, color:activeGrimoire.id===g.id?C.gold:C.text }}>{g.name}</div></div>)}
          <div onClick={() => setShowThemeModal(true)} style={{ padding:"10px 16px", borderRadius:"8px", cursor:"pointer", border:`1px dashed ${C.border}`, display:"flex", alignItems:"center", justifyContent:"center", color:C.textDim, fontSize:"13px", flex:"1 1 140px" }}>+ New</div>
        </div>
        <Label>Theme description</Label>
        <TextArea value={activeGrimoire.desc} onChange={v => setActiveGrimoire({...activeGrimoire, desc:v})} rows={8} />
        <div style={{ display:"flex", gap:"8px", marginTop:"8px" }}>
          <Btn variant="ghost" style={{ fontSize:"12px" }}>✦ AI: Enrich this theme</Btn>
          <Btn variant="ghost" style={{ fontSize:"12px" }}>✦ AI: I just have a vibe, expand it</Btn>
        </div>
      </div>}

      {/* INCANTATIONS */}
      {view==="slides" && <div style={{ display:"flex", height:"100vh" }}>
        <div style={{ width:"260px", borderRight:`1px solid ${C.border}`, padding:"20px 12px", overflowY:"auto" }}>
          <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:"16px", padding:"0 4px" }}>
            <span style={{ fontFamily:serif, fontSize:"18px", fontWeight:600, color:C.goldLight }}>Incantations</span>
            <span style={{ fontSize:"11px", color:C.textDim }}>{slides.length} slides</span>
          </div>
          {slides.map((s,i) => <div key={s.id} onClick={() => setActiveSlide(i)} style={{
            padding:"12px 14px", borderRadius:"8px", cursor:"pointer", marginBottom:"4px", transition:"all 0.15s",
            background:activeSlide===i?C.goldGlow:"transparent", border:`1px solid ${activeSlide===i?C.goldDim:C.border}`,
          }}>
            <div style={{ fontSize:"13px", color:activeSlide===i?C.gold:C.text, fontWeight:500, fontFamily:sans, marginBottom:"2px" }}>{s.title}</div>
            <div style={{ fontSize:"11px", color:C.textDim, overflow:"hidden", textOverflow:"ellipsis", whiteSpace:"nowrap" }}>{s.desc}</div>
          </div>)}
          <div style={{ marginTop:"12px", display:"flex", flexDirection:"column", gap:"6px" }}>
            <div style={{ display:"flex", gap:"6px" }}>
              <Input value={newSlideTitle} onChange={setNewSlideTitle} placeholder="New slide title..." style={{ flex:1, padding:"8px 10px", fontSize:"12px" }} />
              <Btn onClick={() => { if(newSlideTitle.trim()) { setSlides([...slides,{id:Date.now(),title:newSlideTitle,desc:""}]); setNewSlideTitle(""); setActiveSlide(slides.length); } }} style={{ fontSize:"12px", padding:"8px 12px", flexShrink:0 }}>+</Btn>
            </div>
            <Btn variant="ghost" onClick={() => setShowOutlineModal(true)} style={{ fontSize:"12px", width:"100%", textAlign:"center" }}>✦ Generate from outline</Btn>
          </div>
        </div>
        <div style={{ flex:1, padding:"32px", overflowY:"auto" }}>
          {slides[activeSlide] && <>
            <Input value={slides[activeSlide].title} onChange={v => { const n=[...slides]; n[activeSlide]={...n[activeSlide],title:v}; setSlides(n); }}
              style={{ fontFamily:serif, fontSize:"22px", fontWeight:600, background:"transparent", border:"none", padding:"0 0 12px", color:C.goldLight }} />
            <Label>What this slide should show</Label>
            <TextArea value={slides[activeSlide].desc} onChange={v => { const n=[...slides]; n[activeSlide]={...n[activeSlide],desc:v}; setSlides(n); }}
              rows={10} placeholder="Describe what you want this slide to communicate..." />
            <div style={{ display:"flex", gap:"8px", marginTop:"10px", flexWrap:"wrap" }}>
              <Btn variant="ghost" style={{ fontSize:"12px" }}>✦ AI: Expand description</Btn>
              <Btn variant="ghost" style={{ fontSize:"12px" }}>✦ AI: Suggest visual approach</Btn>
              <div style={{ flex:1 }} />
              <Btn disabled={activeSlide===0} onClick={() => { const n=[...slides]; [n[activeSlide-1],n[activeSlide]]=[n[activeSlide],n[activeSlide-1]]; setSlides(n); setActiveSlide(activeSlide-1); }} style={{ fontSize:"12px" }}>↑ Move up</Btn>
              <Btn disabled={activeSlide===slides.length-1} onClick={() => { const n=[...slides]; [n[activeSlide],n[activeSlide+1]]=[n[activeSlide+1],n[activeSlide]]; setSlides(n); setActiveSlide(activeSlide+1); }} style={{ fontSize:"12px" }}>↓ Move down</Btn>
              <Btn variant="danger" onClick={() => { const n=slides.filter((_,i)=>i!==activeSlide); setSlides(n); setActiveSlide(Math.min(activeSlide,n.length-1)); }} style={{ fontSize:"12px" }}>Remove</Btn>
            </div>
          </>}
        </div>
      </div>}

      {/* VISIONS WALL */}
      {view==="wall" && generated && !generating && <div style={{ padding:"24px" }}>
        <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:"20px" }}>
          <div>
            <h2 style={{ fontFamily:serif, fontSize:"24px", fontWeight:600, color:C.goldLight, margin:0 }}>Visions</h2>
            <p style={{ fontSize:"12px", color:C.textDim, margin:"2px 0 0" }}>Grimoire: {activeGrimoire.name} — {Object.keys(selected).length}/{slides.length} selected</p>
          </div>
          {Object.keys(selected).length>0 && <Btn variant="gold" onClick={() => setView("assembly")}>View assembly ({Object.keys(selected).length}/{slides.length}) →</Btn>}
        </div>
        {slides.map((slide,si) => <div key={slide.id} style={{ marginBottom:"20px" }}>
          <div style={{ display:"flex", alignItems:"center", gap:"12px", marginBottom:"8px" }}>
            <span style={{ fontSize:"13px", color:C.gold, fontWeight:500 }}>{slide.title}</span>
            <span style={{ fontSize:"11px", color:C.textDim }}>{selected[si]!==undefined?`v${selected[si]+1} chosen`:"select a vision"}</span>
          </div>
          <div style={{ display:"grid", gridTemplateColumns:`repeat(${variations}, 1fr)`, gap:"8px" }}>
            {Array.from({length:variations}).map((_,vi) => <Variation key={vi} si={si} vi={vi} tid={activeGrimoire.id} isSelected={selected[si]===vi}
              onClick={() => setSelected(prev => prev[si]===vi?(({[si]:_,...r})=>r)(prev):{...prev,[si]:vi})} />)}
          </div>
        </div>)}
      </div>}

      {/* GENERATING */}
      {generating && <div style={{ display:"flex", flexDirection:"column", alignItems:"center", justifyContent:"center", height:"80vh", gap:"16px" }}>
        <div style={{ width:"48px", height:"48px", border:`3px solid ${C.goldGlow}`, borderTopColor:C.gold, borderRadius:"50%", animation:"spin 1s linear infinite" }} />
        <style>{`@keyframes spin { to { transform: rotate(360deg) } }`}</style>
        <p style={{ fontFamily:serif, fontSize:"18px", color:C.gold }}>Summoning {slides.length*variations} visions...</p>
        <p style={{ fontSize:"12px", color:C.textDim }}>Grimoire: {activeGrimoire.name}</p>
      </div>}

      {/* ASSEMBLY */}
      {view==="assembly" && generated && <div style={{ padding:"32px", maxWidth:"900px", margin:"0 auto" }}>
        <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:"24px" }}>
          <div>
            <h2 style={{ fontFamily:serif, fontSize:"24px", fontWeight:600, color:C.goldLight, margin:0 }}>Final cut</h2>
            <p style={{ fontSize:"12px", color:C.textDim, margin:"2px 0 0" }}>{Object.keys(selected).length}/{slides.length} slides selected</p>
          </div>
          <div style={{ display:"flex", gap:"8px" }}>
            <Btn onClick={() => setView("wall")}>← Visions</Btn>
            <Btn>Export to Figma</Btn>
            <Btn variant="gold" disabled={Object.keys(selected).length!==slides.length}>Export PDF →</Btn>
          </div>
        </div>
        {slides.map((slide,si) => { const vi=selected[si]; const has=vi!==undefined;
          return <div key={slide.id} style={{ display:"flex", gap:"16px", alignItems:"flex-start", marginBottom:"16px" }}>
            <div style={{ width:"32px", textAlign:"right", paddingTop:"16px", flexShrink:0 }}><span style={{ fontSize:"13px", color:C.textDim }}>{si+1}</span></div>
            <div style={{ flex:1 }}>
              {has ? <div style={{ position:"relative" }}>
                <Variation si={si} vi={vi} tid={activeGrimoire.id} isSelected={false} onClick={()=>{}} />
                <div style={{ position:"absolute", bottom:"8px", right:"8px" }}>
                  <button onClick={() => { setRefineSlide(si); setRefinePrompt(""); }} style={{ padding:"4px 10px", borderRadius:"4px", fontSize:"11px", cursor:"pointer", background:"rgba(0,0,0,0.6)", color:C.goldLight, border:`1px solid ${C.border}`, fontFamily:sans, backdropFilter:"blur(4px)" }}>✦ Refine</button>
                </div>
              </div> : <div style={{ aspectRatio:"16/9", borderRadius:"6px", border:`1px dashed ${C.border}`, display:"flex", alignItems:"center", justifyContent:"center", color:C.textDim, fontSize:"12px" }}>No vision — {slide.title}</div>}
            </div>
            <div style={{ width:"140px", paddingTop:"8px", flexShrink:0 }}>
              <div style={{ fontSize:"12px", color:C.textMuted, fontWeight:500 }}>{slide.title}</div>
              {has && <div style={{ fontSize:"11px", color:C.textDim, marginTop:"2px" }}>variation {vi+1}</div>}
            </div>
          </div>;
        })}
      </div>}
    </div>

    {/* MODALS */}
    {showOutlineModal && <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.8)", zIndex:50, display:"flex", alignItems:"center", justifyContent:"center", padding:"24px" }} onClick={() => setShowOutlineModal(false)}>
      <div onClick={e=>e.stopPropagation()} style={{ background:C.bgDeep, borderRadius:"12px", border:`1px solid ${C.border}`, padding:"24px", width:"600px", maxWidth:"100%" }}>
        <h3 style={{ fontFamily:serif, fontSize:"20px", color:C.goldLight, margin:"0 0 4px" }}>Generate incantations from outline</h3>
        <p style={{ fontSize:"12px", color:C.textMuted, margin:"0 0 16px" }}>Paste your talk outline, notes, or brain dump.</p>
        <TextArea value={outlineText} onChange={setOutlineText} rows={10} placeholder={"Paste your talk outline here...\n\n- Open with the problem\n- Show the Google engineer tweet\n- Historical context: Alan Kay\n- The real insight\n- Demo\n- What this means"} />
        <div style={{ display:"flex", gap:"8px", marginTop:"12px", justifyContent:"flex-end" }}>
          <Btn onClick={() => setShowOutlineModal(false)}>Cancel</Btn>
          <Btn variant="gold" onClick={() => {
            setSlides([
              {id:1,title:"The identity crisis",desc:"Seven definitions of 'AI agent' on old TV screens. Nobody agrees."},
              {id:2,title:"The Google revelation",desc:"Breaking news. Jaana Dogan tweet — stuck for a year, Claude did it in an hour."},
              {id:3,title:"Destination: Xerox PARC",desc:"Time travel. Green terminal. 1972. Alan Kay invents objects."},
              {id:4,title:"The real object",desc:"What Kay actually meant. Self-contained computers receiving messages."},
              {id:5,title:"Prompt objects",desc:"The new primitive. Periodic table: Functions, Classes, Variables... Prompt Objects."},
              {id:6,title:"Live demo",desc:"Special bulletin. Live demonstration in progress. Please stand by."},
            ]); setShowOutlineModal(false); setActiveSlide(0);
          }}>✦ Generate slides</Btn>
        </div>
      </div>
    </div>}

    {refineSlide!==null && <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.8)", zIndex:50, display:"flex", alignItems:"center", justifyContent:"center", padding:"24px" }} onClick={() => setRefineSlide(null)}>
      <div onClick={e=>e.stopPropagation()} style={{ background:C.bgDeep, borderRadius:"12px", border:`1px solid ${C.border}`, padding:"24px", width:"600px", maxWidth:"100%" }}>
        <h3 style={{ fontFamily:serif, fontSize:"20px", color:C.goldLight, margin:"0 0 16px" }}>Refine: {slides[refineSlide]?.title}</h3>
        <div style={{ marginBottom:"16px" }}><Variation si={refineSlide} vi={selected[refineSlide]||0} tid={activeGrimoire.id} isSelected={false} onClick={()=>{}} /></div>
        <Label>Describe your refinement</Label>
        <TextArea value={refinePrompt} onChange={setRefinePrompt} rows={3} placeholder='e.g. "Make the headline larger" or "Add more static texture"' />
        <div style={{ display:"flex", gap:"8px", marginTop:"12px", justifyContent:"flex-end" }}>
          <Btn onClick={() => setRefineSlide(null)}>Cancel</Btn>
          <Btn variant="gold">✦ Re-conjure with changes</Btn>
        </div>
        <p style={{ fontSize:"11px", color:C.textDim, marginTop:"12px" }}>For compositing (adding screenshots, overlaying images), use Export to Figma.</p>
      </div>
    </div>}

    {showThemeModal && <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.8)", zIndex:50, display:"flex", alignItems:"center", justifyContent:"center", padding:"24px" }} onClick={() => setShowThemeModal(false)}>
      <div onClick={e=>e.stopPropagation()} style={{ background:C.bgDeep, borderRadius:"12px", border:`1px solid ${C.border}`, padding:"24px", width:"600px", maxWidth:"100%" }}>
        <h3 style={{ fontFamily:serif, fontSize:"20px", color:C.goldLight, margin:"0 0 4px" }}>Create a new grimoire</h3>
        <p style={{ fontSize:"12px", color:C.textMuted, margin:"0 0 16px" }}>Describe a visual world.</p>
        <Label>Theme name</Label>
        <Input placeholder="e.g. Vapor Archive, Noir Detective, Solar Punk..." style={{ marginBottom:"12px" }} />
        <Label>Visual description</Label>
        <TextArea rows={8} placeholder={"Describe the world your slides live in.\n\nColors, textures, typography, era, mood..."} />
        <div style={{ display:"flex", gap:"8px", marginTop:"8px" }}>
          <Btn variant="ghost" style={{ fontSize:"12px" }}>✦ AI: I just have a vibe, expand it</Btn>
        </div>
        <div style={{ display:"flex", gap:"8px", marginTop:"16px", justifyContent:"flex-end" }}>
          <Btn onClick={() => setShowThemeModal(false)}>Cancel</Btn>
          <Btn variant="gold" onClick={() => setShowThemeModal(false)}>Create grimoire</Btn>
        </div>
      </div>
    </div>}
  </div>;
}

// ──────────────── MAIN APP ────────────────
export default function Conjure() {
  const [screen, setScreen] = useState("home"); // home | grimoires | newProject | workspace
  const [activeProject, setActiveProject] = useState(null);
  const [grimoires] = useState(allGrimoires);
  const [projects] = useState(allProjects);

  return <div style={{ minHeight:"100vh", background:C.bg, color:C.text, fontFamily:sans }}>
    <link href={FONTS} rel="stylesheet" />

    {screen === "home" && <HomeScreen
      projects={projects} grimoires={grimoires}
      onOpenProject={p => { setActiveProject(p); setScreen("workspace"); }}
      onNewProject={() => setScreen("newProject")}
      onOpenGrimoires={() => setScreen("grimoires")}
    />}

    {screen === "grimoires" && <GrimoireLibrary
      grimoires={grimoires}
      onBack={() => setScreen("home")}
      onCreateNew={() => {}}
      onEdit={() => {}}
    />}

    {screen === "newProject" && <NewProjectFlow
      grimoires={grimoires}
      onCancel={() => setScreen("home")}
      onComplete={config => { setActiveProject({ id:"new", name:config.name, grimoire:config.grimoire, slides:0, selected:0, lastModified:"Just now" }); setScreen("workspace"); }}
    />}

    {screen === "workspace" && activeProject && <Workspace
      project={activeProject} grimoires={grimoires}
      onBackToHome={() => setScreen("home")}
    />}
  </div>;
}
