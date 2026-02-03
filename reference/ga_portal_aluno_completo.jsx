import { useState, useEffect, useRef, useCallback } from "react";

// ============================================================
// GA PERSONAL — Portal do Aluno Expandido
// • Upload de fotos + IA de análise corporal (Claude API)
// • Upload e acompanhamento de exames médicos
// • Medição manual com suporte a múltiplos aparelhos
//   (Anovator, Relaxmedic Intelligence Plus, InBody, etc.)
// • Histórico completo de evolução
// ============================================================

const C = {
  coal: "#0A0A0A", graphite: "#141414", card: "#1A1A1A", steel: "#2A2A2A",
  smoke: "#8A8A8A", fog: "#C4C4C4", white: "#F5F5F0",
  lime: "#C4F53A", limeDim: "#9BC22E", ocean: "#0EA5E9",
  warm: "#F59E0B", coral: "#EF4444", green: "#22C55E",
  purple: "#A855F7", teal: "#14B8A6", rose: "#F43F5E",
};

const F = {
  display: "'Bebas Neue', sans-serif",
  body: "'Outfit', sans-serif",
  mono: "'JetBrains Mono', monospace",
};

// Device configurations with their specific fields
const DEVICES = {
  manual: {
    name: "Medição Manual",
    icon: "✏️",
    desc: "Balança simples, fita métrica, adipômetro",
    color: C.warm,
    fields: ["weight", "bodyFat", "waist", "chest", "hip", "rightArm", "leftArm", "rightThigh", "leftThigh", "rightCalf", "leftCalf"],
  },
  anovator: {
    name: "Anovator",
    icon: "🔬",
    desc: "Torre de bioimpedância profissional com análise postural e segmentar",
    color: C.ocean,
    hasUrl: true,
    fields: ["weight", "bodyFat", "muscleMass", "bmi", "bmr", "bodyWater", "protein", "boneMass", "visceralFat", "bodyAge", "leanMass",
      "muscleRightArm", "muscleLeftArm", "muscleTrunk", "muscleRightLeg", "muscleLeftLeg",
      "fatRightArm", "fatLeftArm", "fatTrunk", "fatRightLeg", "fatLeftLeg",
      "waist", "chest", "hip", "shoulderWidth",
      "shoulderRisk", "spineRisk", "humpbackRisk", "pelvisRisk", "kneeRisk",
      "restingHR", "systolicBP", "diastolicBP", "vitalCapacity"],
  },
  relaxmedic: {
    name: "Relaxmedic Intelligence Plus",
    icon: "⚖️",
    desc: "Balança digital bioimpedância — App RelaxFIT via Bluetooth",
    color: C.purple,
    fields: ["weight", "bodyFat", "muscleMass", "bmi", "bmr", "bodyWater", "protein", "boneMass",
      "visceralFat", "bodyAge", "fatMass", "leanMass", "subcutaneousFat",
      "muscleRightArm", "muscleLeftArm", "muscleRightLeg", "muscleLeftLeg",
      "fatRightLeg", "fatLeftLeg",
      "skeletalMuscle", "muscleRate", "obesityLevel", "idealWeight"],
  },
  inbody: {
    name: "InBody",
    icon: "📊",
    desc: "Analisador profissional de composição corporal",
    color: C.teal,
    fields: ["weight", "bodyFat", "muscleMass", "bmi", "bmr", "bodyWater", "protein", "boneMass",
      "visceralFat", "leanMass", "muscleRightArm", "muscleLeftArm", "muscleTrunk",
      "muscleRightLeg", "muscleLeftLeg", "fatRightArm", "fatLeftArm", "fatTrunk",
      "fatRightLeg", "fatLeftLeg", "waist", "ecw"],
  },
  tanita: {
    name: "Tanita",
    icon: "🏥",
    desc: "Balança profissional de bioimpedância segmentar",
    color: C.green,
    fields: ["weight", "bodyFat", "muscleMass", "bmi", "bmr", "bodyWater", "boneMass", "visceralFat", "bodyAge", "leanMass"],
  },
  omron: {
    name: "Omron",
    icon: "💊",
    desc: "Balança doméstica de bioimpedância",
    color: C.rose,
    fields: ["weight", "bodyFat", "muscleMass", "bmi", "bmr", "visceralFat", "bodyAge", "skeletalMuscle"],
  },
  other: {
    name: "Outro aparelho",
    icon: "📐",
    desc: "Qualquer outro equipamento de medição",
    color: C.smoke,
    fields: ["weight", "bodyFat", "muscleMass", "bmi", "bmr", "bodyWater", "boneMass", "visceralFat",
      "waist", "chest", "hip", "rightArm", "leftArm", "rightThigh", "leftThigh"],
  },
};

// All possible fields
const ALL_FIELDS = {
  weight: { label: "Peso", unit: "kg", group: "comp" },
  bodyFat: { label: "% Gordura Corporal", unit: "%", group: "comp" },
  muscleMass: { label: "Massa Muscular", unit: "kg", group: "comp" },
  bmi: { label: "IMC", unit: "", group: "comp" },
  bmr: { label: "Taxa Metab. Basal", unit: "kcal", group: "comp" },
  bodyWater: { label: "Água Corporal", unit: "%", group: "comp" },
  protein: { label: "Proteína", unit: "kg", group: "comp" },
  boneMass: { label: "Massa Óssea", unit: "kg", group: "comp" },
  visceralFat: { label: "Gordura Visceral", unit: "", group: "comp" },
  bodyAge: { label: "Idade Corporal", unit: "anos", group: "comp" },
  leanMass: { label: "Massa Magra", unit: "kg", group: "comp" },
  fatMass: { label: "Massa Gorda", unit: "kg", group: "comp" },
  subcutaneousFat: { label: "Gordura Subcutânea", unit: "%", group: "comp" },
  skeletalMuscle: { label: "Músculo Esquelético", unit: "%", group: "comp" },
  muscleRate: { label: "Taxa Muscular", unit: "%", group: "comp" },
  obesityLevel: { label: "Nível de Obesidade", unit: "", group: "comp" },
  idealWeight: { label: "Peso Ideal", unit: "kg", group: "comp" },
  ecw: { label: "Água Extracelular", unit: "L", group: "comp" },
  muscleRightArm: { label: "Músculo Braço Dir.", unit: "kg", group: "seg" },
  muscleLeftArm: { label: "Músculo Braço Esq.", unit: "kg", group: "seg" },
  muscleTrunk: { label: "Músculo Tronco", unit: "kg", group: "seg" },
  muscleRightLeg: { label: "Músculo Perna Dir.", unit: "kg", group: "seg" },
  muscleLeftLeg: { label: "Músculo Perna Esq.", unit: "kg", group: "seg" },
  fatRightArm: { label: "Gordura Braço Dir.", unit: "kg", group: "seg" },
  fatLeftArm: { label: "Gordura Braço Esq.", unit: "kg", group: "seg" },
  fatTrunk: { label: "Gordura Tronco", unit: "kg", group: "seg" },
  fatRightLeg: { label: "Gordura Perna Dir.", unit: "kg", group: "seg" },
  fatLeftLeg: { label: "Gordura Perna Esq.", unit: "kg", group: "seg" },
  waist: { label: "Cintura", unit: "cm", group: "dim" },
  chest: { label: "Peito", unit: "cm", group: "dim" },
  hip: { label: "Quadril", unit: "cm", group: "dim" },
  shoulderWidth: { label: "Largura Ombros", unit: "cm", group: "dim" },
  rightArm: { label: "Circ. Braço Dir.", unit: "cm", group: "dim" },
  leftArm: { label: "Circ. Braço Esq.", unit: "cm", group: "dim" },
  rightThigh: { label: "Circ. Coxa Dir.", unit: "cm", group: "dim" },
  leftThigh: { label: "Circ. Coxa Esq.", unit: "cm", group: "dim" },
  rightCalf: { label: "Circ. Panturr. Dir.", unit: "cm", group: "dim" },
  leftCalf: { label: "Circ. Panturr. Esq.", unit: "cm", group: "dim" },
  shoulderRisk: { label: "Risco Ombros", unit: "", group: "post", isText: true },
  spineRisk: { label: "Risco Coluna", unit: "", group: "post", isText: true },
  humpbackRisk: { label: "Risco Cifose", unit: "", group: "post", isText: true },
  pelvisRisk: { label: "Risco Pelve", unit: "", group: "post", isText: true },
  kneeRisk: { label: "Risco Joelho", unit: "", group: "post", isText: true },
  restingHR: { label: "FC Repouso", unit: "bpm", group: "health" },
  systolicBP: { label: "PA Sistólica", unit: "mmHg", group: "health" },
  diastolicBP: { label: "PA Diastólica", unit: "mmHg", group: "health" },
  vitalCapacity: { label: "Capacidade Vital", unit: "mL", group: "health" },
};

const GROUP_LABELS = {
  comp: { label: "Composição Corporal", icon: "⚖️", color: C.ocean },
  seg: { label: "Análise Segmentar", icon: "💪", color: C.lime },
  dim: { label: "Medidas Corporais", icon: "📐", color: C.warm },
  post: { label: "Análise Postural", icon: "🦴", color: C.purple },
  health: { label: "Saúde", icon: "❤️", color: C.coral },
};

// Medical exam types
const EXAM_TYPES = [
  { id: "blood", label: "Exame de Sangue (Hemograma)", icon: "🩸", color: C.coral },
  { id: "hormonal", label: "Painel Hormonal", icon: "⚗️", color: C.purple },
  { id: "thyroid", label: "Tireoide (TSH, T3, T4)", icon: "🦋", color: C.ocean },
  { id: "lipid", label: "Perfil Lipídico (Colesterol)", icon: "🫀", color: C.rose },
  { id: "glycemic", label: "Glicemia / HbA1c", icon: "🍬", color: C.warm },
  { id: "vitamin", label: "Vitaminas e Minerais", icon: "💊", color: C.green },
  { id: "hepatic", label: "Função Hepática (TGO, TGP)", icon: "🫁", color: C.teal },
  { id: "renal", label: "Função Renal (Creatinina, Ureia)", icon: "🫘", color: C.lime },
  { id: "nutritional", label: "Avaliação Nutricional", icon: "🥗", color: C.green },
  { id: "endocrino", label: "Avaliação Endocrinológica", icon: "🧬", color: C.purple },
  { id: "cardio", label: "Avaliação Cardiológica", icon: "❤️", color: C.coral },
  { id: "ortho", label: "Avaliação Ortopédica", icon: "🦴", color: C.smoke },
  { id: "imaging", label: "Exame de Imagem (Raio-X, RM, US)", icon: "📷", color: C.ocean },
  { id: "other", label: "Outro", icon: "📋", color: C.smoke },
];

// Mock data
const MOCK_HISTORY = [
  { id: 1, date: "2026-02-01", device: "anovator", weight: 78.2, bodyFat: 21.3, muscleMass: 34.8, bmi: 24.5, waist: 86, leanMass: 61.5 },
  { id: 2, date: "2026-01-20", device: "relaxmedic", weight: 79.0, bodyFat: 21.8, muscleMass: 34.5, bmi: 24.7, leanMass: 61.8, subcutaneousFat: 18.2, skeletalMuscle: 42.3 },
  { id: 3, date: "2026-01-01", device: "anovator", weight: 80.5, bodyFat: 23.1, muscleMass: 34.0, bmi: 25.2, waist: 89, leanMass: 61.9 },
  { id: 4, date: "2025-12-15", device: "manual", weight: 81.0, bodyFat: null, waist: 90 },
  { id: 5, date: "2025-12-01", device: "anovator", weight: 82.5, bodyFat: 24.5, muscleMass: 33.2, bmi: 25.8, waist: 92, leanMass: 63.8 },
];

const MOCK_PHOTOS = [
  { id: 1, date: "2026-02-01", type: "front", url: null, notes: "Frente — pós Anovator", aiAnalyzed: true },
  { id: 2, date: "2026-02-01", type: "side", url: null, notes: "Lateral — pós Anovator", aiAnalyzed: true },
  { id: 3, date: "2026-01-01", type: "front", url: null, notes: "Frente — início do mês", aiAnalyzed: true },
  { id: 4, date: "2025-12-01", type: "front", url: null, notes: "Frente — avaliação inicial", aiAnalyzed: false },
  { id: 5, date: "2025-12-01", type: "back", url: null, notes: "Costas — avaliação inicial", aiAnalyzed: false },
];

const MOCK_EXAMS = [
  { id: 1, date: "2026-01-20", type: "blood", professional: "Dr. Ricardo M. — Clínico Geral", lab: "Lab São José", notes: "Hemograma completo — todos valores normais", fileName: "hemograma_jan2026.pdf", status: "normal" },
  { id: 2, date: "2026-01-20", type: "hormonal", professional: "Dra. Camila F. — Endocrinologista", lab: "Lab São José", notes: "Testosterona 680ng/dL (normal), Cortisol 15μg/dL (normal)", fileName: "hormonal_jan2026.pdf", status: "normal" },
  { id: 3, date: "2025-11-10", type: "thyroid", professional: "Dra. Camila F. — Endocrinologista", lab: "Exame Lab", notes: "TSH 2.4 (normal), T4 livre 1.2 (normal)", fileName: "tireoide_nov2025.pdf", status: "normal" },
  { id: 4, date: "2025-11-10", type: "lipid", professional: "Dr. Ricardo M. — Clínico Geral", lab: "Exame Lab", notes: "Colesterol total 195, LDL 120, HDL 52 — LDL levemente elevado", fileName: "lipidico_nov2025.pdf", status: "attention" },
  { id: 5, date: "2025-09-05", type: "nutritional", professional: "Dra. Juliana T. — Nutricionista", lab: "—", notes: "Plano alimentar para cutting 2200kcal, ajuste de macros", fileName: "plano_nutricional.pdf", status: "info" },
];

const MOCK_AI_ANALYSIS = {
  date: "2026-02-01",
  overallScore: 82,
  bodySymmetry: 88,
  postureScore: 76,
  muscleDefinition: 79,
  observations: [
    { type: "positive", text: "Boa simetria bilateral em membros superiores — diferença de circunferência entre braços dentro de 0.7cm" },
    { type: "positive", text: "Proporção ombro-cintura indica V-taper em desenvolvimento (razão 1.42)" },
    { type: "attention", text: "Leve anteriorização de ombros detectada na vista lateral — sugestão: fortalecer retratores escapulares" },
    { type: "attention", text: "Inclinação pélvica anterior leve (~8°) — pode indicar encurtamento de flexores de quadril" },
    { type: "metric", text: "Gordura abdominal visualmente consistente com medição de 21.3% (bioimpedância)" },
    { type: "progress", text: "Comparado à foto de dez/2025: redução visível na circunferência abdominal, maior definição em deltoides" },
  ],
  correlations: [
    { label: "% Gordura (foto IA)", value: "~21%", match: true, measured: "21.3%" },
    { label: "Simetria braços", value: "Boa", match: true, measured: "0.7cm diff" },
    { label: "Postura ombros", value: "Leve anteriorização", match: true, measured: "Anovator: Leve" },
    { label: "Pelve", value: "Anteriorização leve", match: true, measured: "Anovator: 5.2°" },
  ],
};

// ===== REUSABLE =====
function LogoMark({ size = 40 }) {
  return <div style={{ width: size, height: size, background: C.lime, borderRadius: size * 0.25, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: F.display, fontSize: size * 0.38, color: C.coal, transform: "rotate(-3deg)", flexShrink: 0 }}>GA</div>;
}

function Btn({ children, variant = "primary", onClick, disabled, full, style: xs }) {
  const base = { padding: "11px 22px", border: "none", borderRadius: 10, fontWeight: 700, fontSize: "0.82rem", cursor: disabled ? "not-allowed" : "pointer", fontFamily: F.body, transition: "all 0.25s", display: "inline-flex", alignItems: "center", gap: 8, width: full ? "100%" : "auto", justifyContent: full ? "center" : undefined, opacity: disabled ? 0.4 : 1 };
  const v = {
    primary: { ...base, background: C.lime, color: C.coal },
    outline: { ...base, background: "transparent", color: C.lime, border: `1.5px solid ${C.lime}33` },
    ghost: { ...base, background: "rgba(255,255,255,0.03)", color: C.fog, border: "1px solid rgba(255,255,255,0.06)" },
    danger: { ...base, background: `${C.coral}15`, color: C.coral, border: `1px solid ${C.coral}25` },
    ocean: { ...base, background: C.ocean, color: C.white },
    purple: { ...base, background: `${C.purple}20`, color: C.purple, border: `1px solid ${C.purple}30` },
  };
  return <button onClick={onClick} disabled={disabled} style={{ ...(v[variant] || v.primary), ...xs }}>{children}</button>;
}

function Card({ children, style: xs, onClick }) {
  return <div onClick={onClick} style={{ background: C.card, borderRadius: 16, padding: 24, border: "1px solid rgba(255,255,255,0.04)", cursor: onClick ? "pointer" : undefined, transition: "all 0.25s", ...xs }}>{children}</div>;
}

function Tag({ children }) {
  return <div style={{ fontFamily: F.mono, fontSize: "0.7rem", color: C.lime, letterSpacing: 3, textTransform: "uppercase", marginBottom: 10 }}>// {children}</div>;
}

function Title({ children }) {
  return <h2 style={{ fontFamily: F.display, fontSize: "clamp(1.8rem, 4vw, 2.8rem)", lineHeight: 1, letterSpacing: -0.5, margin: 0 }}>{children}</h2>;
}

function DeviceBadge({ device }) {
  const d = DEVICES[device] || DEVICES.other;
  return <span style={{ fontSize: "0.65rem", padding: "2px 8px", borderRadius: 6, background: `${d.color}15`, color: d.color, border: `1px solid ${d.color}30`, fontWeight: 600, fontFamily: F.mono, letterSpacing: 0.5 }}>{d.icon} {d.name.toUpperCase()}</span>;
}

function StatusDot({ status }) {
  const map = { normal: C.green, attention: C.warm, critical: C.coral, info: C.ocean };
  return <span style={{ width: 8, height: 8, borderRadius: "50%", background: map[status] || C.smoke, display: "inline-block", flexShrink: 0 }} />;
}

function PhotoPlaceholder({ type, size = 160, date }) {
  const labels = { front: "FRENTE", side: "LATERAL", back: "COSTAS" };
  return (
    <div style={{ width: size, height: size * 1.4, borderRadius: 14, background: `linear-gradient(145deg, ${C.steel}, ${C.graphite})`, border: "1px dashed rgba(255,255,255,0.1)", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 6, flexShrink: 0 }}>
      <span style={{ fontSize: "2rem", opacity: 0.3 }}>📷</span>
      <span style={{ fontSize: "0.7rem", color: C.smoke, fontWeight: 600, letterSpacing: 1 }}>{labels[type] || type}</span>
      {date && <span style={{ fontSize: "0.6rem", color: C.smoke, fontFamily: F.mono }}>{date}</span>}
    </div>
  );
}

function Input({ label, type = "text", value, onChange, placeholder, unit, textarea, required, disabled }) {
  const El = textarea ? "textarea" : "input";
  return (
    <div style={{ marginBottom: 14 }}>
      {label && <label style={{ display: "block", fontSize: "0.78rem", color: C.fog, marginBottom: 5, fontWeight: 500 }}>{label}{required && <span style={{ color: C.coral }}> *</span>}</label>}
      <div style={{ position: "relative" }}>
        <El type={type} value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder} required={required} disabled={disabled} rows={textarea ? 3 : undefined} style={{ width: "100%", padding: "10px 14px", paddingRight: unit ? 48 : 14, background: disabled ? "rgba(255,255,255,0.01)" : "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.08)", borderRadius: 10, color: C.white, fontFamily: F.body, fontSize: "0.88rem", resize: textarea ? "vertical" : "none", opacity: disabled ? 0.5 : 1 }} />
        {unit && <span style={{ position: "absolute", right: 12, top: "50%", transform: "translateY(-50%)", fontSize: "0.72rem", color: C.smoke, fontFamily: F.mono }}>{unit}</span>}
      </div>
    </div>
  );
}

// ===== MAIN APP =====
export default function StudentPortal() {
  const [tab, setTab] = useState("evolution");
  const [showNewMeasure, setShowNewMeasure] = useState(false);
  const [showNewPhoto, setShowNewPhoto] = useState(false);
  const [showNewExam, setShowNewExam] = useState(false);
  const [showAiDetail, setShowAiDetail] = useState(false);
  const [selectedDevice, setSelectedDevice] = useState(null);
  const [measureData, setMeasureData] = useState({});
  const [measureDate, setMeasureDate] = useState(new Date().toISOString().split("T")[0]);
  const [measureNotes, setMeasureNotes] = useState("");
  const [anovatorUrl, setAnovatorUrl] = useState("");
  const [examForm, setExamForm] = useState({ date: new Date().toISOString().split("T")[0], type: "", professional: "", lab: "", notes: "", fileName: "" });
  const [photoForm, setPhotoForm] = useState({ type: "front", notes: "" });
  const [history] = useState(MOCK_HISTORY);
  const [photos] = useState(MOCK_PHOTOS);
  const [exams] = useState(MOCK_EXAMS);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [aiAnalyzing, setAiAnalyzing] = useState(false);

  const handleSave = () => { setSaving(true); setTimeout(() => { setSaving(false); setSaved(true); setTimeout(() => setSaved(false), 2500); }, 1500); };

  const fieldsByGroup = (deviceFields) => {
    const groups = {};
    deviceFields.forEach(key => {
      const f = ALL_FIELDS[key];
      if (!f) return;
      if (!groups[f.group]) groups[f.group] = [];
      groups[f.group].push({ key, ...f });
    });
    return groups;
  };

  const tabs = [
    { id: "evolution", label: "Evolução", icon: "📏" },
    { id: "photos", label: "Fotos & IA", icon: "📸" },
    { id: "exams", label: "Exames", icon: "🩺" },
  ];

  return (
    <div style={{ minHeight: "100vh", background: C.coal, color: C.white, fontFamily: F.body }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Outfit:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500&display=swap');
        * { box-sizing: border-box; margin: 0; padding: 0; }
        ::-webkit-scrollbar { width: 4px; } ::-webkit-scrollbar-track { background: ${C.coal}; } ::-webkit-scrollbar-thumb { background: ${C.lime}; border-radius: 2px; }
        input:focus, textarea:focus, select:focus { outline: none; border-color: ${C.lime}44 !important; }
        @keyframes slideIn { from { opacity: 0; transform: translateY(14px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
        @keyframes pulse { 0%,100% { opacity: 1; } 50% { opacity: .5; } }
        @keyframes spin { to { transform: rotate(360deg); } }
        @keyframes scanline { 0% { top: 0; } 100% { top: 100%; } }
      `}</style>

      {/* Navbar */}
      <nav style={{ position: "sticky", top: 0, zIndex: 1000, background: "rgba(10,10,10,0.92)", backdropFilter: "blur(20px)", borderBottom: `1px solid ${C.lime}12` }}>
        <div style={{ maxWidth: 1100, margin: "0 auto", padding: "12px 24px", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <LogoMark size={34} />
            <div>
              <div style={{ fontFamily: F.display, fontSize: "1rem", letterSpacing: 1.5, lineHeight: 1 }}>PORTAL DO <span style={{ color: C.lime }}>ALUNO</span></div>
              <div style={{ fontFamily: F.mono, fontSize: "0.58rem", color: C.smoke }}>ANA CAROLINA MARTINS</div>
            </div>
          </div>
          <div style={{ display: "flex", gap: 3 }}>
            {tabs.map(t => (
              <button key={t.id} onClick={() => setTab(t.id)} style={{
                padding: "8px 16px", borderRadius: 8, border: "none",
                background: tab === t.id ? `${C.lime}12` : "transparent",
                color: tab === t.id ? C.lime : C.smoke,
                fontFamily: F.body, fontSize: "0.8rem", fontWeight: 600, cursor: "pointer",
              }}>{t.icon} {t.label}</button>
            ))}
          </div>
        </div>
      </nav>

      <main style={{ maxWidth: 1100, margin: "0 auto", padding: "32px 24px" }}>

        {/* ====== TAB: EVOLUÇÃO ====== */}
        {tab === "evolution" && (
          <div style={{ animation: "slideIn 0.4s ease" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 28 }}>
              <div>
                <Tag>FICHA DE EVOLUÇÃO</Tag>
                <Title>HISTÓRICO DE MEDIDAS</Title>
                <p style={{ color: C.smoke, fontSize: "0.88rem", marginTop: 8 }}>Registre medidas de qualquer aparelho e acompanhe sua evolução.</p>
              </div>
              <Btn onClick={() => { setShowNewMeasure(true); setSelectedDevice(null); }}>＋ Nova medição</Btn>
            </div>

            {/* New Measurement Flow */}
            {showNewMeasure && (
              <Card style={{ marginBottom: 28, animation: "slideIn 0.3s ease", border: `1px solid ${C.lime}20` }}>
                {!selectedDevice ? (
                  <>
                    <h3 style={{ fontFamily: F.display, fontSize: "1.3rem", marginBottom: 6 }}>📏 NOVA MEDIÇÃO</h3>
                    <p style={{ fontSize: "0.82rem", color: C.smoke, marginBottom: 20 }}>Selecione o aparelho/método utilizado para esta medição:</p>
                    <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))", gap: 12 }}>
                      {Object.entries(DEVICES).map(([key, dev]) => (
                        <button key={key} onClick={() => { setSelectedDevice(key); setMeasureData({}); }} style={{
                          padding: "16px", background: `${dev.color}08`, border: `1px solid ${dev.color}20`,
                          borderRadius: 14, cursor: "pointer", textAlign: "left", transition: "all 0.2s",
                        }}>
                          <div style={{ fontSize: "1.5rem", marginBottom: 8 }}>{dev.icon}</div>
                          <div style={{ fontWeight: 700, fontSize: "0.88rem", color: C.white, marginBottom: 3 }}>{dev.name}</div>
                          <div style={{ fontSize: "0.72rem", color: C.smoke, lineHeight: 1.5 }}>{dev.desc}</div>
                        </button>
                      ))}
                    </div>
                    <div style={{ display: "flex", justifyContent: "flex-end", marginTop: 16 }}>
                      <Btn variant="ghost" onClick={() => setShowNewMeasure(false)}>Cancelar</Btn>
                    </div>
                  </>
                ) : (
                  <>
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
                      <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                        <button onClick={() => setSelectedDevice(null)} style={{ background: "none", border: "none", color: C.smoke, cursor: "pointer", fontSize: "1rem" }}>←</button>
                        <div>
                          <h3 style={{ fontFamily: F.display, fontSize: "1.2rem", margin: 0 }}>{DEVICES[selectedDevice].icon} {DEVICES[selectedDevice].name.toUpperCase()}</h3>
                          <p style={{ fontSize: "0.72rem", color: C.smoke, margin: 0 }}>Preencha os campos disponíveis — nem todos são obrigatórios</p>
                        </div>
                      </div>
                      <DeviceBadge device={selectedDevice} />
                    </div>

                    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0 20px", marginBottom: 16 }}>
                      <Input label="Data da medição" type="date" value={measureDate} onChange={setMeasureDate} required />
                      {DEVICES[selectedDevice].hasUrl && (
                        <Input label="URL do relatório Anovator" value={anovatorUrl} onChange={setAnovatorUrl} placeholder="https://www.anovator.com/body/mobile8.0.html?id=..." />
                      )}
                    </div>

                    {Object.entries(fieldsByGroup(DEVICES[selectedDevice].fields)).map(([groupKey, fields]) => (
                      <div key={groupKey} style={{ background: `${GROUP_LABELS[groupKey].color}06`, border: `1px solid ${GROUP_LABELS[groupKey].color}12`, borderRadius: 14, padding: "14px 18px", marginBottom: 14 }}>
                        <div style={{ fontSize: "0.72rem", fontWeight: 700, color: GROUP_LABELS[groupKey].color, marginBottom: 12, letterSpacing: 1, display: "flex", alignItems: "center", gap: 6 }}>
                          {GROUP_LABELS[groupKey].icon} {GROUP_LABELS[groupKey].label.toUpperCase()}
                        </div>
                        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(160px, 1fr))", gap: "0 14px" }}>
                          {fields.map(f => f.isText ? (
                            <Input key={f.key} label={f.label} value={measureData[f.key] || ""} onChange={v => setMeasureData(p => ({ ...p, [f.key]: v }))} placeholder="—" />
                          ) : (
                            <Input key={f.key} label={f.label} type="number" value={measureData[f.key] || ""} onChange={v => setMeasureData(p => ({ ...p, [f.key]: v }))} unit={f.unit} placeholder="0.0" />
                          ))}
                        </div>
                      </div>
                    ))}

                    <Input label="Observações" value={measureNotes} onChange={setMeasureNotes} placeholder="Condições: jejum, pós-treino, horário, aparelho calibrado..." textarea />

                    <div style={{ display: "flex", justifyContent: "space-between", marginTop: 4 }}>
                      <Btn variant="ghost" onClick={() => setShowNewMeasure(false)}>Cancelar</Btn>
                      <Btn onClick={() => { handleSave(); setTimeout(() => setShowNewMeasure(false), 2000); }} disabled={!measureData.weight}>
                        {saving ? "⟳ Salvando..." : saved ? "✓ Salvo!" : "💾 Salvar medição"}
                      </Btn>
                    </div>
                  </>
                )}
              </Card>
            )}

            {/* Summary Cards */}
            <div style={{ display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: 14, marginBottom: 28 }}>
              {[
                { label: "Peso", value: history[0]?.weight, prev: history[history.length - 1]?.weight, unit: "kg", color: C.lime },
                { label: "% Gordura", value: history[0]?.bodyFat, prev: history[history.length - 1]?.bodyFat, unit: "%", color: C.ocean },
                { label: "M. Muscular", value: history[0]?.muscleMass, prev: history[history.length - 1]?.muscleMass, unit: "kg", color: C.green },
                { label: "IMC", value: history[0]?.bmi, prev: history[history.length - 1]?.bmi, unit: "", color: C.warm },
                { label: "Cintura", value: history[0]?.waist, prev: history[history.length - 1]?.waist, unit: "cm", color: C.purple },
              ].map((m, i) => {
                const diff = m.value && m.prev ? (m.value - m.prev).toFixed(1) : null;
                return (
                  <Card key={i} style={{ padding: 16 }}>
                    <div style={{ fontSize: "0.65rem", color: C.smoke, textTransform: "uppercase", letterSpacing: 1.5, marginBottom: 2 }}>{m.label}</div>
                    <div style={{ fontFamily: F.display, fontSize: "1.8rem", color: m.color, lineHeight: 1 }}>{m.value ?? "—"}<span style={{ fontSize: "0.7rem", color: C.smoke }}>{m.unit}</span></div>
                    {diff && <div style={{ fontSize: "0.68rem", color: parseFloat(diff) < 0 ? C.green : C.coral, marginTop: 2 }}>{parseFloat(diff) > 0 ? "↑" : "↓"} {Math.abs(diff)}{m.unit}</div>}
                  </Card>
                );
              })}
            </div>

            {/* History */}
            <Card style={{ padding: 0, overflow: "hidden" }}>
              <div style={{ padding: "14px 20px", borderBottom: "1px solid rgba(255,255,255,0.04)", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <span style={{ fontFamily: F.display, fontSize: "1.05rem", letterSpacing: 1 }}>HISTÓRICO</span>
                <span style={{ fontSize: "0.72rem", color: C.smoke }}>{history.length} registros</span>
              </div>
              <div style={{ overflowX: "auto" }}>
                <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "0.8rem" }}>
                  <thead>
                    <tr style={{ borderBottom: "1px solid rgba(255,255,255,0.06)" }}>
                      {["Data", "Aparelho", "Peso", "% Gord.", "M. Musc.", "IMC", "Cintura", "M. Magra"].map(h => (
                        <th key={h} style={{ padding: "10px 14px", textAlign: "left", color: C.smoke, fontWeight: 600, fontSize: "0.68rem", letterSpacing: 1, textTransform: "uppercase", whiteSpace: "nowrap" }}>{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {history.map((r, i) => (
                      <tr key={r.id} style={{ borderBottom: "1px solid rgba(255,255,255,0.02)", background: i === 0 ? `${C.lime}05` : "transparent" }}>
                        <td style={{ padding: "10px 14px", fontFamily: F.mono, fontSize: "0.78rem", color: C.lime }}>{r.date}</td>
                        <td style={{ padding: "10px 14px" }}><DeviceBadge device={r.device} /></td>
                        {["weight", "bodyFat", "muscleMass", "bmi", "waist", "leanMass"].map(k => (
                          <td key={k} style={{ padding: "10px 14px", fontFamily: F.mono, color: r[k] != null ? C.white : C.steel }}>{r[k] ?? "—"}</td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </Card>
          </div>
        )}

        {/* ====== TAB: FOTOS & IA ====== */}
        {tab === "photos" && (
          <div style={{ animation: "slideIn 0.4s ease" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 28 }}>
              <div>
                <Tag>FOTOS & ANÁLISE IA</Tag>
                <Title>ACOMPANHAMENTO VISUAL</Title>
                <p style={{ color: C.smoke, fontSize: "0.88rem", marginTop: 8 }}>Fotos de evolução com análise inteligente por IA para cruzamento com dados reais.</p>
              </div>
              <Btn onClick={() => setShowNewPhoto(true)}>📸 Nova foto</Btn>
            </div>

            {/* Upload Form */}
            {showNewPhoto && (
              <Card style={{ marginBottom: 28, animation: "slideIn 0.3s ease", border: `1px solid ${C.purple}25` }}>
                <h3 style={{ fontFamily: F.display, fontSize: "1.2rem", marginBottom: 16 }}>📸 UPLOAD DE FOTO</h3>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 16, marginBottom: 20 }}>
                  {["front", "side", "back"].map(type => (
                    <button key={type} onClick={() => setPhotoForm(p => ({ ...p, type }))} style={{
                      padding: 20, borderRadius: 14, border: photoForm.type === type ? `2px solid ${C.lime}60` : "2px dashed rgba(255,255,255,0.08)",
                      background: photoForm.type === type ? `${C.lime}08` : "transparent",
                      cursor: "pointer", textAlign: "center",
                    }}>
                      <div style={{ fontSize: "2.5rem", marginBottom: 8, opacity: 0.6 }}>📷</div>
                      <div style={{ fontWeight: 700, fontSize: "0.85rem", color: C.white }}>
                        {{ front: "Frente", side: "Lateral", back: "Costas" }[type]}
                      </div>
                      <div style={{ fontSize: "0.72rem", color: C.smoke, marginTop: 4 }}>Clique ou arraste</div>
                    </button>
                  ))}
                </div>
                <div style={{
                  padding: 40, borderRadius: 14, border: "2px dashed rgba(255,255,255,0.1)",
                  background: "rgba(255,255,255,0.02)", textAlign: "center", marginBottom: 16,
                }}>
                  <div style={{ fontSize: "2.5rem", marginBottom: 8 }}>☁️</div>
                  <div style={{ fontSize: "0.9rem", fontWeight: 600, color: C.fog, marginBottom: 4 }}>Arraste a foto ou clique para selecionar</div>
                  <div style={{ fontSize: "0.75rem", color: C.smoke }}>JPG, PNG ou HEIF — máx. 20MB</div>
                </div>
                <Input label="Observações" value={photoForm.notes} onChange={v => setPhotoForm(p => ({ ...p, notes: v }))} placeholder="Condições: iluminação, horário, pós-treino..." />
                <div style={{ display: "flex", gap: 10, justifyContent: "flex-end" }}>
                  <Btn variant="ghost" onClick={() => setShowNewPhoto(false)}>Cancelar</Btn>
                  <Btn variant="purple" onClick={() => { setAiAnalyzing(true); setTimeout(() => setAiAnalyzing(false), 3000); }}>
                    🤖 Upload + Análise IA
                  </Btn>
                </div>

                {/* AI Analyzing animation */}
                {aiAnalyzing && (
                  <div style={{ marginTop: 20, padding: 24, background: `${C.purple}08`, border: `1px solid ${C.purple}20`, borderRadius: 14, animation: "fadeIn 0.3s ease" }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 16 }}>
                      <div style={{ width: 24, height: 24, border: `2px solid ${C.purple}`, borderTop: "2px solid transparent", borderRadius: "50%", animation: "spin 0.8s linear infinite" }} />
                      <span style={{ fontWeight: 700, color: C.purple }}>Analisando com IA...</span>
                    </div>
                    <div style={{ position: "relative", height: 200, borderRadius: 12, overflow: "hidden", background: C.graphite, border: "1px solid rgba(255,255,255,0.04)" }}>
                      <PhotoPlaceholder type="front" size={100} />
                      <div style={{ position: "absolute", left: 0, right: 0, height: 2, background: `linear-gradient(90deg, transparent, ${C.lime}, transparent)`, animation: "scanline 2s linear infinite" }} />
                      <div style={{ position: "absolute", top: 10, right: 10, fontSize: "0.65rem", color: C.lime, fontFamily: F.mono, animation: "pulse 1s infinite" }}>
                        Detectando pose → Analisando simetria → Estimando composição → Cruzando dados...
                      </div>
                    </div>
                  </div>
                )}
              </Card>
            )}

            {/* AI Analysis Result */}
            <Card style={{ marginBottom: 24, border: `1px solid ${C.purple}15` }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
                <div>
                  <h3 style={{ fontFamily: F.display, fontSize: "1.2rem", margin: 0 }}>🤖 ANÁLISE IA — ÚLTIMA AVALIAÇÃO</h3>
                  <p style={{ fontSize: "0.72rem", color: C.smoke, margin: "4px 0 0" }}>
                    {MOCK_AI_ANALYSIS.date} — Pose estimation (MoveNet) + Análise visual (Claude Sonnet) + Cruzamento bioimpedância
                  </p>
                </div>
                <Btn variant="ghost" onClick={() => setShowAiDetail(!showAiDetail)} style={{ fontSize: "0.75rem" }}>
                  {showAiDetail ? "▲ Recolher" : "▼ Expandir"}
                </Btn>
              </div>

              {/* Scores */}
              <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 14, marginBottom: 20 }}>
                {[
                  { label: "Score Geral", value: MOCK_AI_ANALYSIS.overallScore, color: C.lime },
                  { label: "Simetria", value: MOCK_AI_ANALYSIS.bodySymmetry, color: C.ocean },
                  { label: "Postura", value: MOCK_AI_ANALYSIS.postureScore, color: C.warm },
                  { label: "Definição Muscular", value: MOCK_AI_ANALYSIS.muscleDefinition, color: C.purple },
                ].map((s, i) => (
                  <div key={i} style={{ padding: 14, background: `${s.color}08`, borderRadius: 12, border: `1px solid ${s.color}15`, textAlign: "center" }}>
                    <div style={{ fontFamily: F.display, fontSize: "2.2rem", color: s.color, lineHeight: 1 }}>{s.value}</div>
                    <div style={{ fontSize: "0.68rem", color: C.smoke, letterSpacing: 1, textTransform: "uppercase", marginTop: 2 }}>{s.label}</div>
                  </div>
                ))}
              </div>

              {showAiDetail && (
                <div style={{ animation: "slideIn 0.3s ease" }}>
                  {/* Observations */}
                  <div style={{ marginBottom: 20 }}>
                    <div style={{ fontSize: "0.75rem", fontWeight: 700, color: C.fog, marginBottom: 10, letterSpacing: 1 }}>OBSERVAÇÕES DA IA</div>
                    {MOCK_AI_ANALYSIS.observations.map((obs, i) => (
                      <div key={i} style={{
                        display: "flex", gap: 10, padding: "10px 14px", marginBottom: 6,
                        borderRadius: 10, fontSize: "0.82rem", color: C.fog, lineHeight: 1.6,
                        background: obs.type === "positive" ? `${C.green}06` : obs.type === "progress" ? `${C.lime}06` : obs.type === "metric" ? `${C.ocean}06` : `${C.warm}06`,
                        borderLeft: `3px solid ${obs.type === "positive" ? C.green : obs.type === "progress" ? C.lime : obs.type === "metric" ? C.ocean : C.warm}`,
                      }}>
                        <span style={{ flexShrink: 0 }}>{{ positive: "✅", attention: "⚠️", metric: "📊", progress: "📈" }[obs.type]}</span>
                        {obs.text}
                      </div>
                    ))}
                  </div>

                  {/* Correlations */}
                  <div style={{ fontSize: "0.75rem", fontWeight: 700, color: C.fog, marginBottom: 10, letterSpacing: 1 }}>CRUZAMENTO IA × BIOIMPEDÂNCIA</div>
                  <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
                    {MOCK_AI_ANALYSIS.correlations.map((c, i) => (
                      <div key={i} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "10px 14px", background: "rgba(255,255,255,0.02)", borderRadius: 10, border: "1px solid rgba(255,255,255,0.04)" }}>
                        <div>
                          <div style={{ fontSize: "0.78rem", fontWeight: 600, color: C.white }}>{c.label}</div>
                          <div style={{ fontSize: "0.7rem", color: C.smoke }}>IA: {c.value}</div>
                        </div>
                        <div style={{ textAlign: "right" }}>
                          <div style={{ fontSize: "0.7rem", color: C.smoke }}>Medido: {c.measured}</div>
                          <div style={{ fontSize: "0.65rem", color: c.match ? C.green : C.warm, fontWeight: 700 }}>{c.match ? "✓ Consistente" : "⚠ Divergente"}</div>
                        </div>
                      </div>
                    ))}
                  </div>

                  {/* Tech Stack Info */}
                  <div style={{ marginTop: 16, padding: 14, background: `${C.purple}06`, border: `1px solid ${C.purple}12`, borderRadius: 10, fontSize: "0.72rem", color: C.purple, lineHeight: 1.7 }}>
                    <strong>Stack de IA:</strong> TensorFlow.js MoveNet (pose estimation no browser, 33 keypoints) → Claude Sonnet (análise visual: simetria, proporções, estimativa composição) → Cruzamento automático com dados de bioimpedância (Anovator/Relaxmedic/InBody) para validação cruzada.
                  </div>
                </div>
              )}
            </Card>

            {/* Photo Timeline */}
            <Card>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
                <span style={{ fontFamily: F.display, fontSize: "1.1rem", letterSpacing: 1 }}>TIMELINE DE FOTOS</span>
                <span style={{ fontSize: "0.72rem", color: C.smoke }}>{photos.length} fotos</span>
              </div>
              {/* Group by date */}
              {[...new Set(photos.map(p => p.date))].map(date => (
                <div key={date} style={{ marginBottom: 20 }}>
                  <div style={{ fontSize: "0.78rem", fontFamily: F.mono, color: C.lime, marginBottom: 10 }}>{date}</div>
                  <div style={{ display: "flex", gap: 12, overflowX: "auto", paddingBottom: 8 }}>
                    {photos.filter(p => p.date === date).map(p => (
                      <div key={p.id} style={{ flexShrink: 0 }}>
                        <PhotoPlaceholder type={p.type} size={120} date={p.date} />
                        <div style={{ display: "flex", alignItems: "center", gap: 4, marginTop: 6 }}>
                          {p.aiAnalyzed && <span style={{ fontSize: "0.6rem", padding: "1px 5px", borderRadius: 4, background: `${C.purple}15`, color: C.purple, fontWeight: 700 }}>IA ✓</span>}
                          <span style={{ fontSize: "0.68rem", color: C.smoke }}>{p.notes}</span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ))}

              {/* Comparison */}
              <div style={{ borderTop: "1px solid rgba(255,255,255,0.04)", paddingTop: 20, marginTop: 12 }}>
                <div style={{ fontSize: "0.8rem", fontWeight: 700, color: C.fog, marginBottom: 14 }}>📸 COMPARATIVO ANTES × AGORA</div>
                <div style={{ display: "flex", gap: 24, alignItems: "flex-end" }}>
                  <div style={{ textAlign: "center" }}>
                    <PhotoPlaceholder type="front" size={150} date="2025-12-01" />
                    <div style={{ marginTop: 8, fontFamily: F.mono, fontSize: "0.72rem", color: C.coral }}>DEZ/2025</div>
                    <div style={{ fontSize: "0.72rem", color: C.smoke }}>82.5kg · 24.5% gord.</div>
                  </div>
                  <div style={{ fontFamily: F.display, fontSize: "2rem", color: C.lime, paddingBottom: 40 }}>→</div>
                  <div style={{ textAlign: "center" }}>
                    <PhotoPlaceholder type="front" size={150} date="2026-02-01" />
                    <div style={{ marginTop: 8, fontFamily: F.mono, fontSize: "0.72rem", color: C.lime }}>FEV/2026</div>
                    <div style={{ fontSize: "0.72rem", color: C.smoke }}>78.2kg · 21.3% gord.</div>
                  </div>
                  <Card style={{ padding: 16, flex: 1 }}>
                    <div style={{ fontFamily: F.display, fontSize: "1rem", marginBottom: 8 }}>📊 DELTA</div>
                    {[
                      { label: "Peso", delta: "-4.3kg", color: C.green },
                      { label: "Gordura", delta: "-3.2%", color: C.green },
                      { label: "M. Muscular", delta: "+1.6kg", color: C.lime },
                      { label: "Cintura", delta: "-6cm", color: C.green },
                    ].map((d, i) => (
                      <div key={i} style={{ display: "flex", justifyContent: "space-between", padding: "4px 0", fontSize: "0.82rem" }}>
                        <span style={{ color: C.fog }}>{d.label}</span>
                        <span style={{ fontFamily: F.mono, color: d.color, fontWeight: 700 }}>{d.delta}</span>
                      </div>
                    ))}
                  </Card>
                </div>
              </div>
            </Card>
          </div>
        )}

        {/* ====== TAB: EXAMES ====== */}
        {tab === "exams" && (
          <div style={{ animation: "slideIn 0.4s ease" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 28 }}>
              <div>
                <Tag>EXAMES MÉDICOS</Tag>
                <Title>SAÚDE COMPLETA</Title>
                <p style={{ color: C.smoke, fontSize: "0.88rem", marginTop: 8 }}>Faça upload dos seus exames e mantenha seu personal e profissionais de saúde informados.</p>
              </div>
              <Btn onClick={() => setShowNewExam(true)}>📄 Novo exame</Btn>
            </div>

            {/* New Exam Form */}
            {showNewExam && (
              <Card style={{ marginBottom: 28, animation: "slideIn 0.3s ease", border: `1px solid ${C.teal}25` }}>
                <h3 style={{ fontFamily: F.display, fontSize: "1.2rem", marginBottom: 16 }}>🩺 UPLOAD DE EXAME</h3>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0 20px" }}>
                  <Input label="Data do exame" type="date" value={examForm.date} onChange={v => setExamForm(p => ({ ...p, date: v }))} required />
                  <div style={{ marginBottom: 14 }}>
                    <label style={{ display: "block", fontSize: "0.78rem", color: C.fog, marginBottom: 5, fontWeight: 500 }}>Tipo de exame <span style={{ color: C.coral }}>*</span></label>
                    <select value={examForm.type} onChange={e => setExamForm(p => ({ ...p, type: e.target.value }))} style={{
                      width: "100%", padding: "10px 14px", background: "rgba(255,255,255,0.04)",
                      border: "1px solid rgba(255,255,255,0.08)", borderRadius: 10,
                      color: C.white, fontFamily: F.body, fontSize: "0.88rem", appearance: "none",
                    }}>
                      <option value="" style={{ background: C.graphite }}>Selecione...</option>
                      {EXAM_TYPES.map(t => <option key={t.id} value={t.id} style={{ background: C.graphite }}>{t.icon} {t.label}</option>)}
                    </select>
                  </div>
                  <Input label="Profissional" value={examForm.professional} onChange={v => setExamForm(p => ({ ...p, professional: v }))} placeholder="Dr. Nome — Especialidade" />
                  <Input label="Laboratório / Clínica" value={examForm.lab} onChange={v => setExamForm(p => ({ ...p, lab: v }))} placeholder="Nome do laboratório" />
                </div>

                {/* File Upload */}
                <div style={{
                  padding: 32, borderRadius: 14, border: "2px dashed rgba(255,255,255,0.1)",
                  background: "rgba(255,255,255,0.02)", textAlign: "center", marginBottom: 16,
                }}>
                  <div style={{ fontSize: "2rem", marginBottom: 6 }}>📎</div>
                  <div style={{ fontSize: "0.88rem", fontWeight: 600, color: C.fog, marginBottom: 4 }}>Arraste o arquivo do exame ou clique para selecionar</div>
                  <div style={{ fontSize: "0.72rem", color: C.smoke }}>PDF, JPG, PNG ou HEIF — máx. 25MB</div>
                </div>

                <Input label="Notas / Resultados relevantes" value={examForm.notes} onChange={v => setExamForm(p => ({ ...p, notes: v }))} placeholder="Valores fora da faixa, observações do médico..." textarea />

                <div style={{
                  padding: 14, background: `${C.teal}06`, border: `1px solid ${C.teal}12`, borderRadius: 10,
                  fontSize: "0.72rem", color: C.teal, lineHeight: 1.7, marginBottom: 16,
                }}>
                  <strong>🔒 Privacidade:</strong> Seus exames ficam criptografados e só são acessíveis por você e pelo Guilherme (se autorizado). Profissionais de saúde podem receber acesso via link temporário.
                </div>

                <div style={{ display: "flex", gap: 10, justifyContent: "flex-end" }}>
                  <Btn variant="ghost" onClick={() => setShowNewExam(false)}>Cancelar</Btn>
                  <Btn onClick={() => { handleSave(); setTimeout(() => setShowNewExam(false), 2000); }} disabled={!examForm.type}>
                    {saving ? "⟳ Salvando..." : saved ? "✓ Salvo!" : "📤 Upload exame"}
                  </Btn>
                </div>
              </Card>
            )}

            {/* Info Banner */}
            <div style={{
              display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 14, marginBottom: 24,
            }}>
              {[
                { icon: "👨‍⚕️", title: "Médico / Clínico", desc: "Hemograma, lipídico, glicemia, função renal/hepática", color: C.ocean },
                { icon: "🧬", title: "Endocrinologista", desc: "Painel hormonal, tireoide, cortisol, testosterona", color: C.purple },
                { icon: "🥗", title: "Nutricionista", desc: "Plano alimentar, avaliação nutricional, diário alimentar", color: C.green },
              ].map((p, i) => (
                <Card key={i} style={{ padding: 18, borderLeft: `3px solid ${p.color}` }}>
                  <div style={{ fontSize: "1.3rem", marginBottom: 6 }}>{p.icon}</div>
                  <div style={{ fontWeight: 700, fontSize: "0.85rem", marginBottom: 2 }}>{p.title}</div>
                  <div style={{ fontSize: "0.72rem", color: C.smoke, lineHeight: 1.5 }}>{p.desc}</div>
                </Card>
              ))}
            </div>

            {/* Exams List */}
            <Card style={{ padding: 0, overflow: "hidden" }}>
              <div style={{ padding: "14px 20px", borderBottom: "1px solid rgba(255,255,255,0.04)", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <span style={{ fontFamily: F.display, fontSize: "1.05rem", letterSpacing: 1 }}>TODOS OS EXAMES</span>
                <span style={{ fontSize: "0.72rem", color: C.smoke }}>{exams.length} documentos</span>
              </div>
              {exams.map((exam, i) => {
                const type = EXAM_TYPES.find(t => t.id === exam.type) || EXAM_TYPES[EXAM_TYPES.length - 1];
                return (
                  <div key={exam.id} style={{
                    display: "grid", gridTemplateColumns: "auto 1fr auto",
                    gap: 16, alignItems: "center", padding: "16px 20px",
                    borderBottom: i < exams.length - 1 ? "1px solid rgba(255,255,255,0.02)" : "none",
                    transition: "background 0.2s",
                  }}>
                    <div style={{
                      width: 44, height: 44, borderRadius: 12, background: `${type.color}12`,
                      border: `1px solid ${type.color}25`, display: "flex", alignItems: "center",
                      justifyContent: "center", fontSize: "1.3rem",
                    }}>{type.icon}</div>
                    <div>
                      <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 2 }}>
                        <span style={{ fontWeight: 700, fontSize: "0.88rem" }}>{type.label}</span>
                        <StatusDot status={exam.status} />
                      </div>
                      <div style={{ fontSize: "0.75rem", color: C.smoke }}>{exam.professional}</div>
                      <div style={{ fontSize: "0.72rem", color: C.smoke, marginTop: 2 }}>{exam.notes}</div>
                    </div>
                    <div style={{ textAlign: "right" }}>
                      <div style={{ fontFamily: F.mono, fontSize: "0.75rem", color: C.lime, marginBottom: 4 }}>{exam.date}</div>
                      <div style={{ fontSize: "0.68rem", color: C.smoke }}>{exam.lab}</div>
                      <Btn variant="ghost" style={{ marginTop: 6, padding: "4px 10px", fontSize: "0.68rem" }}>📄 {exam.fileName}</Btn>
                    </div>
                  </div>
                );
              })}
            </Card>

            {/* Sharing */}
            <Card style={{ marginTop: 24, border: `1px solid ${C.ocean}15` }}>
              <h3 style={{ fontFamily: F.display, fontSize: "1.1rem", marginBottom: 12 }}>🔗 COMPARTILHAMENTO</h3>
              <p style={{ fontSize: "0.82rem", color: C.smoke, marginBottom: 16, lineHeight: 1.7 }}>Gere links temporários para compartilhar seus exames com profissionais de saúde.</p>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 10 }}>
                <Btn variant="ghost" full style={{ justifyContent: "center" }}>👨‍⚕️ Link p/ Médico</Btn>
                <Btn variant="ghost" full style={{ justifyContent: "center" }}>🧬 Link p/ Endócrino</Btn>
                <Btn variant="ghost" full style={{ justifyContent: "center" }}>🥗 Link p/ Nutricionista</Btn>
              </div>
            </Card>
          </div>
        )}
      </main>

      {/* Footer */}
      <footer style={{ borderTop: "1px solid rgba(255,255,255,0.03)", padding: "20px", textAlign: "center", marginTop: 48 }}>
        <span style={{ fontSize: "0.68rem", color: C.smoke }}>© 2026 GA Personal · Guilherme Almeida</span>
        <div style={{ display: "flex", gap: 5, justifyContent: "center", marginTop: 6 }}>
          {["Elixir", "Phoenix", "Vue", "PostgreSQL", "TensorFlow.js", "Claude API"].map(t => (
            <span key={t} style={{ padding: "1px 5px", background: `${C.lime}08`, borderRadius: 3, fontSize: "0.6rem", color: C.lime, fontFamily: F.mono }}>{t}</span>
          ))}
        </div>
      </footer>
    </div>
  );
}
