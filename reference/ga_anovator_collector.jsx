import { useState, useEffect, useRef, useCallback } from "react";

// ============================================================
// GA PERSONAL — Coletor de Dados Anovator (Bioimpedância)
// Ferramenta para importar dados do relatório Anovator 
// para a ficha do aluno no sistema GA Personal
// ============================================================

// All Anovator exam fields mapped from the Vue template analysis
const ANOVATOR_FIELD_MAP = {
  // === COMPOSIÇÃO CORPORAL BÁSICA ===
  basicComposition: {
    label: "Composição Corporal",
    icon: "⚖️",
    fields: {
      weight: { label: "Peso", unit: "kg", dbField: "weight" },
      fatWeight: { label: "Peso de Gordura", unit: "kg", dbField: "fat_weight" },
      muscleWeight: { label: "Peso Muscular", unit: "kg", dbField: "muscle_weight" },
      bodyFatRate: { label: "% Gordura Corporal", unit: "%", dbField: "body_fat_percentage" },
      bmi: { label: "IMC", unit: "", dbField: "bmi" },
      bmr: { label: "Taxa Metab. Basal", unit: "kcal", dbField: "bmr" },
      bodyWater: { label: "Água Corporal", unit: "%", dbField: "body_water" },
      protein: { label: "Proteína", unit: "kg", dbField: "protein" },
      boneMass: { label: "Massa Óssea", unit: "kg", dbField: "bone_mass" },
      visceralFat: { label: "Gordura Visceral", unit: "", dbField: "visceral_fat" },
      bodyAge: { label: "Idade Corporal", unit: "anos", dbField: "body_age" },
      leanMass: { label: "Massa Magra", unit: "kg", dbField: "lean_mass" },
    }
  },

  // === ANÁLISE SEGMENTAR — MÚSCULOS ===
  segmentalMuscle: {
    label: "Análise Segmentar — Músculos",
    icon: "💪",
    fields: {
      muscleRightArm: { label: "Braço Direito", unit: "kg", dbField: "muscle_right_arm" },
      muscleLeftArm: { label: "Braço Esquerdo", unit: "kg", dbField: "muscle_left_arm" },
      muscleTrunk: { label: "Tronco", unit: "kg", dbField: "muscle_trunk" },
      muscleRightLeg: { label: "Perna Direita", unit: "kg", dbField: "muscle_right_leg" },
      muscleLeftLeg: { label: "Perna Esquerda", unit: "kg", dbField: "muscle_left_leg" },
      muscleRightArmRate: { label: "Braço Dir. (%ideal)", unit: "%", dbField: "muscle_right_arm_rate" },
      muscleLeftArmRate: { label: "Braço Esq. (%ideal)", unit: "%", dbField: "muscle_left_arm_rate" },
      muscleTrunkRate: { label: "Tronco (%ideal)", unit: "%", dbField: "muscle_trunk_rate" },
      muscleRightLegRate: { label: "Perna Dir. (%ideal)", unit: "%", dbField: "muscle_right_leg_rate" },
      muscleLeftLegRate: { label: "Perna Esq. (%ideal)", unit: "%", dbField: "muscle_left_leg_rate" },
    }
  },

  // === ANÁLISE SEGMENTAR — GORDURA ===
  segmentalFat: {
    label: "Análise Segmentar — Gordura",
    icon: "📊",
    fields: {
      fatRightArm: { label: "Braço Direito", unit: "kg", dbField: "fat_right_arm" },
      fatLeftArm: { label: "Braço Esquerdo", unit: "kg", dbField: "fat_left_arm" },
      fatTrunk: { label: "Tronco", unit: "kg", dbField: "fat_trunk" },
      fatRightLeg: { label: "Perna Direita", unit: "kg", dbField: "fat_right_leg" },
      fatLeftLeg: { label: "Perna Esquerda", unit: "kg", dbField: "fat_left_leg" },
      fatRightArmRate: { label: "Braço Dir. (%ideal)", unit: "%", dbField: "fat_right_arm_rate" },
      fatLeftArmRate: { label: "Braço Esq. (%ideal)", unit: "%", dbField: "fat_left_arm_rate" },
      fatTrunkRate: { label: "Tronco (%ideal)", unit: "%", dbField: "fat_trunk_rate" },
      fatRightLegRate: { label: "Perna Dir. (%ideal)", unit: "%", dbField: "fat_right_leg_rate" },
      fatLeftLegRate: { label: "Perna Esq. (%ideal)", unit: "%", dbField: "fat_left_leg_rate" },
    }
  },

  // === DIMENSÕES CORPORAIS ===
  bodyDimensions: {
    label: "Dimensões Corporais",
    icon: "📐",
    fields: {
      shoulderWidth: { label: "Largura Ombros", unit: "cm", dbField: "shoulder_width" },
      chestCirc: { label: "Circ. Peito", unit: "cm", dbField: "chest" },
      waistCirc: { label: "Circ. Cintura", unit: "cm", dbField: "waist" },
      hipCirc: { label: "Circ. Quadril", unit: "cm", dbField: "hip" },
      rightArmCirc: { label: "Circ. Braço Dir.", unit: "cm", dbField: "right_arm_circ" },
      leftArmCirc: { label: "Circ. Braço Esq.", unit: "cm", dbField: "left_arm_circ" },
      rightThighCirc: { label: "Circ. Coxa Dir.", unit: "cm", dbField: "right_thigh" },
      leftThighCirc: { label: "Circ. Coxa Esq.", unit: "cm", dbField: "left_thigh" },
      rightCalfCirc: { label: "Circ. Panturr. Dir.", unit: "cm", dbField: "right_calf" },
      leftCalfCirc: { label: "Circ. Panturr. Esq.", unit: "cm", dbField: "left_calf" },
    }
  },

  // === RISCOS POSTURAIS ===
  posturalRisk: {
    label: "Análise Postural",
    icon: "🦴",
    fields: {
      shoulderDiffAbs: { label: "Desnível Ombros", unit: "cm", dbField: "shoulder_diff" },
      shoulderRiskStr: { label: "Risco Ombros", unit: "", dbField: "shoulder_risk" },
      spineRiskStr: { label: "Risco Coluna", unit: "", dbField: "spine_risk" },
      spineDiff: { label: "Desvio Coluna", unit: "cm", dbField: "spine_diff" },
      headAngle: { label: "Inclinação Cabeça", unit: "°", dbField: "head_angle" },
      headRiskStr: { label: "Risco Cabeça", unit: "", dbField: "head_risk" },
      humpbackAngle: { label: "Ângulo Cifose", unit: "°", dbField: "humpback_angle" },
      humpbackRiskStr: { label: "Risco Cifose", unit: "", dbField: "humpback_risk" },
      pelvisAngle: { label: "Ângulo Pelve", unit: "°", dbField: "pelvis_angle" },
      pelvisRiskStr: { label: "Risco Pelve", unit: "", dbField: "pelvis_risk" },
      kneeAngle: { label: "Ângulo Joelho", unit: "°", dbField: "knee_angle" },
      kneeRiskStr: { label: "Risco Joelho", unit: "", dbField: "knee_risk" },
      headLeadAngle: { label: "Anteriorização Cabeça", unit: "°", dbField: "head_lead_angle" },
      frontHeadRiskStr: { label: "Risco Ant. Cabeça", unit: "", dbField: "front_head_risk" },
    }
  },

  // === CARDIO / PERFORMANCE ===
  performance: {
    label: "Performance & Saúde",
    icon: "❤️",
    fields: {
      restingHeartRate: { label: "FC Repouso", unit: "bpm", dbField: "resting_heart_rate" },
      heartFun: { label: "Função Cardíaca", unit: "", dbField: "heart_function" },
      bloodMaxPressure: { label: "Pressão Sistólica", unit: "mmHg", dbField: "systolic_bp" },
      bloodMinPressure: { label: "Pressão Diastólica", unit: "mmHg", dbField: "diastolic_bp" },
      sportSafe: { label: "Segurança Exercício", unit: "", dbField: "sport_safety" },
      balanceAngle: { label: "Ângulo Equilíbrio", unit: "°", dbField: "balance_angle" },
      balanceTxt: { label: "Avaliação Equilíbrio", unit: "", dbField: "balance_rating" },
      vitalCapacity: { label: "Capacidade Vital", unit: "mL", dbField: "vital_capacity" },
      agility: { label: "Tempo de Reação", unit: "ms", dbField: "reaction_time" },
    }
  },

  // === METAS & PLANO ===
  plan: {
    label: "Plano de Exercício",
    icon: "🎯",
    fields: {
      sportGoal: { label: "Meta Exercício Semanal", unit: "min", dbField: "sport_goal" },
      aerobicGoal: { label: "Meta Aeróbico", unit: "min", dbField: "aerobic_goal" },
      enduGoal: { label: "Meta Resistência", unit: "min", dbField: "endurance_goal" },
      anaGoal: { label: "Meta Anaeróbico", unit: "min", dbField: "anaerobic_goal" },
      caloriesInput: { label: "Calorias Recomendadas", unit: "kcal", dbField: "calories_input" },
    }
  },

  // === FORMA CORPORAL ===
  bodyShape: {
    label: "Classificação Corporal",
    icon: "🏋️",
    fields: {
      bodyShape: { label: "Tipo Corporal", unit: "", dbField: "body_shape_index" },
      predictiveValue: { label: "Altura Prevista", unit: "cm", dbField: "predictive_height" },
    }
  }
};

// Risk level color mapping
const riskColors = {
  "Baixo": "#C4F53A",
  "Low": "#C4F53A",
  "Leve": "#84CC16",
  "Mild": "#84CC16",
  "Médio": "#F59E0B",
  "Medium": "#F59E0B",
  "Alto": "#EF4444",
  "Height": "#EF4444",
  "High": "#EF4444",
  "Muito Alto": "#DC2626",
  "Very High": "#DC2626",
};

const getRiskColor = (value) => {
  if (!value || typeof value !== 'string') return "#8A8A8A";
  for (const [key, color] of Object.entries(riskColors)) {
    if (value.toLowerCase().includes(key.toLowerCase())) return color;
  }
  return "#8A8A8A";
};

// Sample data simulating what comes from Anovator report
const SAMPLE_ANOVATOR_DATA = {
  weight: 82.5, fatWeight: 18.7, muscleWeight: 35.2, bodyFatRate: 22.7,
  bmi: 25.8, bmr: 1780, bodyWater: 55.3, protein: 11.2, boneMass: 3.1,
  visceralFat: 8, bodyAge: 34, leanMass: 63.8,
  muscleRightArm: 3.2, muscleLeftArm: 3.0, muscleTrunk: 25.1,
  muscleRightLeg: 9.8, muscleLeftLeg: 9.5,
  muscleRightArmRate: 105, muscleLeftArmRate: 98, muscleTrunkRate: 102,
  muscleRightLegRate: 107, muscleLeftLegRate: 104,
  fatRightArm: 1.1, fatLeftArm: 1.0, fatTrunk: 10.2,
  fatRightLeg: 3.4, fatLeftLeg: 3.3,
  fatRightArmRate: 112, fatLeftArmRate: 108, fatTrunkRate: 118,
  fatRightLegRate: 105, fatLeftLegRate: 103,
  shoulderWidth: 46.2, chestCirc: 102.3, waistCirc: 88.5, hipCirc: 101.2,
  rightArmCirc: 34.5, leftArmCirc: 33.8, rightThighCirc: 57.2,
  leftThighCirc: 56.8, rightCalfCirc: 38.1, leftCalfCirc: 37.9,
  shoulderDiffAbs: 0.8, shoulderRiskStr: "Baixo", spineRiskStr: "Baixo",
  spineDiff: 0.3, headAngle: 2.1, headRiskStr: "Baixo",
  humpbackAngle: 8.5, humpbackRiskStr: "Leve", pelvisAngle: 5.2,
  pelvisRiskStr: "Baixo", kneeAngle: 3.1, kneeRiskStr: "Baixo",
  headLeadAngle: 12.3, frontHeadRiskStr: "Leve",
  restingHeartRate: 68, heartFun: "Bom", bloodMaxPressure: 122,
  bloodMinPressure: 78, sportSafe: "Seguro", balanceAngle: 1.8,
  balanceTxt: "Bom", vitalCapacity: 3850, agility: 280,
  sportGoal: 300, aerobicGoal: 180, enduGoal: 80, anaGoal: 40,
  caloriesInput: 2200, bodyShape: 4, predictiveValue: 178.5,
  leftLegAngle: -2, rightLegAngle: -1.5,
};

// Student list for demo
const STUDENTS = [
  { id: 1, name: "Ana Carolina M.", objective: "Emagrecimento", avatar: "AC" },
  { id: 2, name: "Roberto S. Filho", objective: "Hipertrofia", avatar: "RS" },
  { id: 3, name: "Mariana K.", objective: "Hybrid Training", avatar: "MK" },
  { id: 4, name: "Carlos Eduardo", objective: "Funcional", avatar: "CE" },
  { id: 5, name: "Juliana R.", objective: "Emagrecimento", avatar: "JR" },
];

// Body shape labels
const BODY_SHAPES = [
  "Magro Oculto", "Magro", "Normal", "Musculoso", "Sobrepeso",
  "Obeso", "Muito Obeso", "Musculoso Pesado", "Muito Musculoso"
];

export default function AnovatorCollector() {
  const [activeTab, setActiveTab] = useState("import");
  const [anovatorUrl, setAnovatorUrl] = useState("");
  const [selectedStudent, setSelectedStudent] = useState(null);
  const [importedData, setImportedData] = useState(null);
  const [editedData, setEditedData] = useState({});
  const [expandedSections, setExpandedSections] = useState(new Set(["basicComposition"]));
  const [importStatus, setImportStatus] = useState("idle");
  const [saveStatus, setSaveStatus] = useState("idle");
  const [searchQuery, setSearchQuery] = useState("");
  const [showStudentPicker, setShowStudentPicker] = useState(false);
  const [manualEntry, setManualEntry] = useState(false);
  const urlInputRef = useRef(null);

  const filteredStudents = STUDENTS.filter(s =>
    s.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const toggleSection = (key) => {
    setExpandedSections(prev => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  };

  const expandAll = () => {
    setExpandedSections(new Set(Object.keys(ANOVATOR_FIELD_MAP)));
  };

  const collapseAll = () => {
    setExpandedSections(new Set());
  };

  // Simulate importing data from Anovator URL
  const handleImport = useCallback(() => {
    if (!anovatorUrl.includes("anovator.com")) {
      setImportStatus("error");
      return;
    }
    setImportStatus("loading");
    // Simulate API call / scraping
    setTimeout(() => {
      setImportedData(SAMPLE_ANOVATOR_DATA);
      setEditedData(SAMPLE_ANOVATOR_DATA);
      setImportStatus("success");
      setActiveTab("review");
      expandAll();
    }, 2000);
  }, [anovatorUrl]);

  const handleFieldEdit = (fieldKey, value) => {
    setEditedData(prev => ({ ...prev, [fieldKey]: value }));
  };

  const handleSave = () => {
    if (!selectedStudent) {
      setShowStudentPicker(true);
      return;
    }
    setSaveStatus("saving");
    setTimeout(() => {
      setSaveStatus("saved");
      setTimeout(() => setSaveStatus("idle"), 3000);
    }, 1500);
  };

  const generateApiPayload = () => {
    const payload = { student_id: selectedStudent?.id, assessed_at: new Date().toISOString().split('T')[0], source: "anovator", anovator_url: anovatorUrl };
    for (const [sectionKey, section] of Object.entries(ANOVATOR_FIELD_MAP)) {
      for (const [fieldKey, field] of Object.entries(section.fields)) {
        if (editedData[fieldKey] !== undefined) {
          payload[field.dbField] = editedData[fieldKey];
        }
      }
    }
    return payload;
  };

  return (
    <div style={{
      minHeight: "100vh",
      background: "#0A0A0A",
      color: "#F5F5F0",
      fontFamily: "'Outfit', system-ui, -apple-system, sans-serif",
    }}>
      {/* Google Fonts */}
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Outfit:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');
        
        * { box-sizing: border-box; margin: 0; padding: 0; }
        
        ::-webkit-scrollbar { width: 5px; }
        ::-webkit-scrollbar-track { background: #0A0A0A; }
        ::-webkit-scrollbar-thumb { background: #C4F53A; border-radius: 3px; }
        
        input:focus, textarea:focus { outline: none; }
        
        @keyframes slideIn { from { opacity: 0; transform: translateY(12px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }
        @keyframes spin { to { transform: rotate(360deg); } }
        @keyframes shimmer { 0% { background-position: -200% 0; } 100% { background-position: 200% 0; } }
        @keyframes checkmark { 0% { transform: scale(0); } 50% { transform: scale(1.2); } 100% { transform: scale(1); } }
        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
      `}</style>

      {/* Header */}
      <header style={{
        borderBottom: "1px solid rgba(196,245,58,0.08)",
        background: "rgba(26,26,26,0.6)",
        backdropFilter: "blur(20px)",
        position: "sticky", top: 0, zIndex: 100,
      }}>
        <div style={{
          maxWidth: 1100, margin: "0 auto", padding: "14px 24px",
          display: "flex", alignItems: "center", justifyContent: "space-between",
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{
              width: 40, height: 40, background: "#C4F53A", borderRadius: 10,
              display: "flex", alignItems: "center", justifyContent: "center",
              fontFamily: "'Bebas Neue', sans-serif", fontSize: "1.2rem",
              color: "#0A0A0A", transform: "rotate(-3deg)",
            }}>GA</div>
            <div>
              <div style={{
                fontFamily: "'Bebas Neue', sans-serif", fontSize: "1.1rem",
                letterSpacing: 1.5, lineHeight: 1,
              }}>
                SISTEMA <span style={{ color: "#C4F53A" }}>GA PERSONAL</span>
              </div>
              <div style={{
                fontFamily: "'JetBrains Mono', monospace",
                fontSize: "0.65rem", color: "#8A8A8A", letterSpacing: 1,
              }}>BIOIMPEDÂNCIA ANOVATOR</div>
            </div>
          </div>
          
          {/* Selected student badge */}
          {selectedStudent && (
            <div style={{
              display: "flex", alignItems: "center", gap: 10,
              background: "rgba(196,245,58,0.08)", border: "1px solid rgba(196,245,58,0.15)",
              borderRadius: 10, padding: "6px 14px",
              animation: "fadeIn 0.3s ease",
            }}>
              <div style={{
                width: 30, height: 30, borderRadius: 8,
                background: "linear-gradient(135deg, #C4F53A, #0EA5E9)",
                display: "flex", alignItems: "center", justifyContent: "center",
                fontSize: "0.7rem", fontWeight: 700, color: "#0A0A0A",
              }}>{selectedStudent.avatar}</div>
              <div>
                <div style={{ fontSize: "0.8rem", fontWeight: 600 }}>{selectedStudent.name}</div>
                <div style={{ fontSize: "0.65rem", color: "#C4F53A" }}>{selectedStudent.objective}</div>
              </div>
              <button onClick={() => setSelectedStudent(null)} style={{
                background: "none", border: "none", color: "#8A8A8A",
                cursor: "pointer", fontSize: "1rem", marginLeft: 4,
              }}>×</button>
            </div>
          )}
        </div>
      </header>

      {/* Main Content */}
      <main style={{ maxWidth: 1100, margin: "0 auto", padding: "32px 24px" }}>
        
        {/* Tab Navigation */}
        <div style={{
          display: "flex", gap: 4, marginBottom: 32,
          background: "#1A1A1A", borderRadius: 12, padding: 4,
          border: "1px solid rgba(255,255,255,0.04)",
        }}>
          {[
            { id: "import", label: "1. Importar", icon: "📥" },
            { id: "review", label: "2. Revisar Dados", icon: "🔍" },
            { id: "mapping", label: "3. Mapeamento DB", icon: "🗄️" },
          ].map(tab => (
            <button key={tab.id} onClick={() => setActiveTab(tab.id)} style={{
              flex: 1, padding: "12px 16px", background: activeTab === tab.id ? "rgba(196,245,58,0.1)" : "transparent",
              border: activeTab === tab.id ? "1px solid rgba(196,245,58,0.2)" : "1px solid transparent",
              borderRadius: 10, color: activeTab === tab.id ? "#C4F53A" : "#8A8A8A",
              fontFamily: "'Outfit', sans-serif", fontWeight: 600, fontSize: "0.85rem",
              cursor: "pointer", transition: "all 0.3s ease",
              display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
            }}>
              <span>{tab.icon}</span> {tab.label}
            </button>
          ))}
        </div>

        {/* ===== TAB 1: IMPORT ===== */}
        {activeTab === "import" && (
          <div style={{ animation: "slideIn 0.4s ease" }}>
            {/* Student Selector */}
            <div style={{
              background: "#1A1A1A", borderRadius: 16, padding: 28,
              border: "1px solid rgba(255,255,255,0.04)", marginBottom: 24,
            }}>
              <div style={{
                fontFamily: "'Bebas Neue', sans-serif", fontSize: "1.3rem",
                letterSpacing: 1, marginBottom: 16,
                display: "flex", alignItems: "center", gap: 10,
              }}>
                <span>👤</span> SELECIONAR ALUNO
              </div>
              
              <input
                type="text" placeholder="Buscar aluno pelo nome..."
                value={searchQuery} onChange={e => setSearchQuery(e.target.value)}
                style={{
                  width: "100%", padding: "12px 16px", background: "rgba(255,255,255,0.04)",
                  border: "1px solid rgba(255,255,255,0.08)", borderRadius: 10,
                  color: "#F5F5F0", fontFamily: "'Outfit', sans-serif", fontSize: "0.9rem",
                  marginBottom: 16,
                }}
              />
              
              <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
                {filteredStudents.map(student => (
                  <button key={student.id} onClick={() => setSelectedStudent(student)} style={{
                    display: "flex", alignItems: "center", gap: 10,
                    padding: "10px 16px", borderRadius: 12,
                    background: selectedStudent?.id === student.id ? "rgba(196,245,58,0.12)" : "rgba(255,255,255,0.03)",
                    border: selectedStudent?.id === student.id ? "1px solid rgba(196,245,58,0.3)" : "1px solid rgba(255,255,255,0.06)",
                    color: "#F5F5F0", cursor: "pointer", transition: "all 0.2s ease",
                    fontFamily: "'Outfit', sans-serif",
                  }}>
                    <div style={{
                      width: 36, height: 36, borderRadius: 10,
                      background: selectedStudent?.id === student.id
                        ? "linear-gradient(135deg, #C4F53A, #0EA5E9)"
                        : "#2A2A2A",
                      display: "flex", alignItems: "center", justifyContent: "center",
                      fontSize: "0.75rem", fontWeight: 700,
                      color: selectedStudent?.id === student.id ? "#0A0A0A" : "#8A8A8A",
                    }}>{student.avatar}</div>
                    <div style={{ textAlign: "left" }}>
                      <div style={{ fontSize: "0.85rem", fontWeight: 600 }}>{student.name}</div>
                      <div style={{ fontSize: "0.7rem", color: "#8A8A8A" }}>{student.objective}</div>
                    </div>
                  </button>
                ))}
              </div>
            </div>

            {/* Import Options */}
            <div style={{
              display: "grid", gridTemplateColumns: "1fr 1fr", gap: 24,
            }}>
              {/* Option 1: URL Import */}
              <div style={{
                background: "#1A1A1A", borderRadius: 16, padding: 28,
                border: manualEntry ? "1px solid rgba(255,255,255,0.04)" : "1px solid rgba(196,245,58,0.15)",
                transition: "all 0.3s ease",
              }}>
                <div style={{
                  display: "flex", alignItems: "center", justifyContent: "space-between",
                  marginBottom: 20,
                }}>
                  <div style={{
                    fontFamily: "'Bebas Neue', sans-serif", fontSize: "1.3rem",
                    letterSpacing: 1, display: "flex", alignItems: "center", gap: 10,
                  }}>
                    <span>🔗</span> IMPORTAR VIA URL
                  </div>
                  <button onClick={() => setManualEntry(false)} style={{
                    padding: "4px 12px", borderRadius: 6,
                    background: !manualEntry ? "rgba(196,245,58,0.15)" : "transparent",
                    border: "1px solid rgba(196,245,58,0.2)", color: "#C4F53A",
                    fontSize: "0.7rem", fontWeight: 600, cursor: "pointer",
                    fontFamily: "'Outfit', sans-serif",
                  }}>ATIVO</button>
                </div>
                
                <p style={{ fontSize: "0.85rem", color: "#8A8A8A", marginBottom: 16, lineHeight: 1.6 }}>
                  Cole o link do relatório Anovator que o aluno recebeu.
                  O sistema vai extrair automaticamente todos os dados.
                </p>
                
                <div style={{ position: "relative", marginBottom: 16 }}>
                  <input
                    ref={urlInputRef}
                    type="url"
                    placeholder="https://www.anovator.com/body/mobile8.0.html?id=..."
                    value={anovatorUrl}
                    onChange={e => { setAnovatorUrl(e.target.value); setImportStatus("idle"); }}
                    style={{
                      width: "100%", padding: "14px 16px", paddingRight: 80,
                      background: "rgba(255,255,255,0.04)",
                      border: importStatus === "error"
                        ? "1px solid rgba(239,68,68,0.5)"
                        : "1px solid rgba(255,255,255,0.08)",
                      borderRadius: 10, color: "#F5F5F0",
                      fontFamily: "'JetBrains Mono', monospace", fontSize: "0.8rem",
                    }}
                  />
                  <button onClick={() => {
                    navigator.clipboard?.readText?.().then(text => {
                      setAnovatorUrl(text);
                    }).catch(() => {});
                  }} style={{
                    position: "absolute", right: 8, top: "50%", transform: "translateY(-50%)",
                    padding: "6px 12px", background: "rgba(196,245,58,0.1)",
                    border: "1px solid rgba(196,245,58,0.2)", borderRadius: 6,
                    color: "#C4F53A", fontSize: "0.7rem", fontWeight: 600,
                    cursor: "pointer", fontFamily: "'Outfit', sans-serif",
                  }}>COLAR</button>
                </div>
                
                {importStatus === "error" && (
                  <div style={{ fontSize: "0.8rem", color: "#EF4444", marginBottom: 12 }}>
                    ⚠️ URL inválida. Use o link completo do relatório Anovator.
                  </div>
                )}
                
                <button onClick={handleImport} disabled={!anovatorUrl || importStatus === "loading"} style={{
                  width: "100%", padding: "14px", background: anovatorUrl ? "#C4F53A" : "#2A2A2A",
                  color: anovatorUrl ? "#0A0A0A" : "#8A8A8A",
                  border: "none", borderRadius: 10, fontWeight: 700,
                  fontSize: "0.9rem", cursor: anovatorUrl ? "pointer" : "not-allowed",
                  fontFamily: "'Outfit', sans-serif", letterSpacing: 0.5,
                  transition: "all 0.3s ease",
                  display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
                }}>
                  {importStatus === "loading" ? (
                    <>
                      <span style={{ display: "inline-block", animation: "spin 1s linear infinite" }}>⟳</span>
                      Importando dados...
                    </>
                  ) : importStatus === "success" ? (
                    <><span style={{ animation: "checkmark 0.4s ease" }}>✓</span> Dados importados!</>
                  ) : (
                    <>Importar dados →</>
                  )}
                </button>

                <div style={{
                  marginTop: 16, padding: 12, background: "rgba(14,165,233,0.06)",
                  border: "1px solid rgba(14,165,233,0.12)", borderRadius: 8,
                  fontSize: "0.75rem", color: "#0EA5E9", lineHeight: 1.6,
                }}>
                  <strong>Como funciona:</strong> O sistema faz uma requisição ao relatório
                  Anovator, extrai os dados do objeto <code style={{ background: "rgba(14,165,233,0.1)", padding: "1px 4px", borderRadius: 3 }}>exam</code> via
                  API, e mapeia cada campo para o banco de dados do GA Personal.
                </div>
              </div>

              {/* Option 2: Manual Entry */}
              <div style={{
                background: "#1A1A1A", borderRadius: 16, padding: 28,
                border: manualEntry ? "1px solid rgba(196,245,58,0.15)" : "1px solid rgba(255,255,255,0.04)",
                transition: "all 0.3s ease",
              }}>
                <div style={{
                  display: "flex", alignItems: "center", justifyContent: "space-between",
                  marginBottom: 20,
                }}>
                  <div style={{
                    fontFamily: "'Bebas Neue', sans-serif", fontSize: "1.3rem",
                    letterSpacing: 1, display: "flex", alignItems: "center", gap: 10,
                  }}>
                    <span>✏️</span> ENTRADA MANUAL
                  </div>
                  <button onClick={() => setManualEntry(true)} style={{
                    padding: "4px 12px", borderRadius: 6,
                    background: manualEntry ? "rgba(196,245,58,0.15)" : "transparent",
                    border: "1px solid rgba(196,245,58,0.2)", color: "#C4F53A",
                    fontSize: "0.7rem", fontWeight: 600, cursor: "pointer",
                    fontFamily: "'Outfit', sans-serif",
                  }}>{manualEntry ? "ATIVO" : "USAR"}</button>
                </div>
                
                <p style={{ fontSize: "0.85rem", color: "#8A8A8A", marginBottom: 16, lineHeight: 1.6 }}>
                  Caso o link não funcione, você pode digitar os dados manualmente
                  a partir do relatório impresso ou do celular do aluno.
                </p>
                
                <button onClick={() => {
                  setManualEntry(true);
                  setImportedData({});
                  setEditedData({});
                  setActiveTab("review");
                  expandAll();
                }} style={{
                  width: "100%", padding: "14px",
                  background: "transparent",
                  color: "#C4F53A",
                  border: "1.5px solid rgba(196,245,58,0.3)",
                  borderRadius: 10, fontWeight: 700,
                  fontSize: "0.9rem", cursor: "pointer",
                  fontFamily: "'Outfit', sans-serif", letterSpacing: 0.5,
                  transition: "all 0.3s ease",
                }}>
                  Preencher manualmente →
                </button>

                <div style={{
                  marginTop: 16, padding: 12, background: "rgba(245,158,11,0.06)",
                  border: "1px solid rgba(245,158,11,0.12)", borderRadius: 8,
                  fontSize: "0.75rem", color: "#F59E0B", lineHeight: 1.6,
                }}>
                  <strong>Dica:</strong> Peça ao aluno para compartilhar o link do relatório
                  via WhatsApp. É mais rápido e evita erros de digitação.
                </div>
              </div>
            </div>

            {/* Architecture Info */}
            <div style={{
              marginTop: 24, background: "#1A1A1A", borderRadius: 16, padding: 28,
              border: "1px solid rgba(255,255,255,0.04)",
            }}>
              <div style={{
                fontFamily: "'Bebas Neue', sans-serif", fontSize: "1.2rem",
                letterSpacing: 1, marginBottom: 16,
                display: "flex", alignItems: "center", gap: 10,
              }}>
                <span>🏗️</span> FLUXO DE INTEGRAÇÃO
              </div>
              <div style={{
                display: "flex", alignItems: "center", gap: 8, flexWrap: "wrap",
                fontFamily: "'JetBrains Mono', monospace", fontSize: "0.75rem",
              }}>
                {[
                  { label: "Aluno faz\nbioimpedância", color: "#0EA5E9" },
                  { label: "→" },
                  { label: "Recebe link\nAnovator", color: "#0EA5E9" },
                  { label: "→" },
                  { label: "Compartilha\ncom o Gui", color: "#F59E0B" },
                  { label: "→" },
                  { label: "Sistema GA\nextrai dados", color: "#C4F53A" },
                  { label: "→" },
                  { label: "Gui revisa\ne confirma", color: "#C4F53A" },
                  { label: "→" },
                  { label: "Salvo na\nficha do aluno", color: "#C4F53A" },
                ].map((step, i) => (
                  step.color ? (
                    <div key={i} style={{
                      padding: "10px 14px", background: `${step.color}11`,
                      border: `1px solid ${step.color}33`, borderRadius: 8,
                      color: step.color, textAlign: "center", whiteSpace: "pre-line",
                      lineHeight: 1.4, minWidth: 90,
                    }}>{step.label}</div>
                  ) : (
                    <span key={i} style={{ color: "#4A4A4A", fontSize: "1.1rem" }}>{step.label}</span>
                  )
                ))}
              </div>
            </div>
          </div>
        )}

        {/* ===== TAB 2: REVIEW DATA ===== */}
        {activeTab === "review" && (
          <div style={{ animation: "slideIn 0.4s ease" }}>
            {/* Controls */}
            <div style={{
              display: "flex", justifyContent: "space-between", alignItems: "center",
              marginBottom: 24,
            }}>
              <div style={{ display: "flex", gap: 8 }}>
                <button onClick={expandAll} style={{
                  padding: "8px 14px", background: "rgba(255,255,255,0.04)",
                  border: "1px solid rgba(255,255,255,0.08)", borderRadius: 8,
                  color: "#C4C4C4", fontSize: "0.8rem", cursor: "pointer",
                  fontFamily: "'Outfit', sans-serif",
                }}>▼ Expandir tudo</button>
                <button onClick={collapseAll} style={{
                  padding: "8px 14px", background: "rgba(255,255,255,0.04)",
                  border: "1px solid rgba(255,255,255,0.08)", borderRadius: 8,
                  color: "#C4C4C4", fontSize: "0.8rem", cursor: "pointer",
                  fontFamily: "'Outfit', sans-serif",
                }}>▲ Recolher tudo</button>
              </div>
              
              <button onClick={handleSave} style={{
                padding: "10px 24px", background: saveStatus === "saved" ? "#16A34A" : "#C4F53A",
                color: "#0A0A0A", border: "none", borderRadius: 10,
                fontWeight: 700, fontSize: "0.9rem", cursor: "pointer",
                fontFamily: "'Outfit', sans-serif",
                display: "flex", alignItems: "center", gap: 8,
                transition: "all 0.3s ease",
              }}>
                {saveStatus === "saving" ? (
                  <><span style={{ animation: "spin 1s linear infinite" }}>⟳</span> Salvando...</>
                ) : saveStatus === "saved" ? (
                  <><span style={{ animation: "checkmark 0.4s ease" }}>✓</span> Salvo na ficha!</>
                ) : (
                  <>💾 Salvar na ficha do aluno</>
                )}
              </button>
            </div>

            {/* Data Sections */}
            {Object.entries(ANOVATOR_FIELD_MAP).map(([sectionKey, section]) => {
              const isExpanded = expandedSections.has(sectionKey);
              return (
                <div key={sectionKey} style={{
                  background: "#1A1A1A", borderRadius: 14,
                  border: "1px solid rgba(255,255,255,0.04)",
                  marginBottom: 12, overflow: "hidden",
                  transition: "all 0.3s ease",
                }}>
                  {/* Section Header */}
                  <button onClick={() => toggleSection(sectionKey)} style={{
                    width: "100%", display: "flex", alignItems: "center",
                    justifyContent: "space-between", padding: "16px 24px",
                    background: "transparent", border: "none", color: "#F5F5F0",
                    cursor: "pointer", fontFamily: "'Outfit', sans-serif",
                  }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                      <span style={{ fontSize: "1.2rem" }}>{section.icon}</span>
                      <span style={{
                        fontFamily: "'Bebas Neue', sans-serif",
                        fontSize: "1.1rem", letterSpacing: 1,
                      }}>{section.label}</span>
                      <span style={{
                        fontSize: "0.7rem", color: "#8A8A8A",
                        background: "rgba(255,255,255,0.04)",
                        padding: "2px 8px", borderRadius: 4,
                        fontFamily: "'JetBrains Mono', monospace",
                      }}>{Object.keys(section.fields).length} campos</span>
                    </div>
                    <span style={{
                      transform: isExpanded ? "rotate(180deg)" : "rotate(0deg)",
                      transition: "transform 0.3s ease", fontSize: "0.8rem", color: "#8A8A8A",
                    }}>▼</span>
                  </button>
                  
                  {/* Section Content */}
                  {isExpanded && (
                    <div style={{
                      padding: "0 24px 20px",
                      display: "grid",
                      gridTemplateColumns: "repeat(auto-fill, minmax(220px, 1fr))",
                      gap: 12,
                      animation: "slideIn 0.3s ease",
                    }}>
                      {Object.entries(section.fields).map(([fieldKey, field]) => {
                        const value = editedData[fieldKey];
                        const isRisk = field.dbField?.includes("risk");
                        return (
                          <div key={fieldKey} style={{
                            padding: "12px 14px",
                            background: "rgba(255,255,255,0.02)",
                            border: "1px solid rgba(255,255,255,0.04)",
                            borderRadius: 10,
                            transition: "all 0.2s ease",
                          }}>
                            <div style={{
                              fontSize: "0.7rem", color: "#8A8A8A",
                              marginBottom: 6, fontWeight: 500,
                              display: "flex", justifyContent: "space-between",
                            }}>
                              <span>{field.label}</span>
                              {field.unit && (
                                <span style={{
                                  fontFamily: "'JetBrains Mono', monospace",
                                  fontSize: "0.65rem", color: "#4A4A4A",
                                }}>{field.unit}</span>
                              )}
                            </div>
                            {isRisk ? (
                              <div style={{
                                fontSize: "0.95rem", fontWeight: 600,
                                color: getRiskColor(value),
                              }}>
                                {value || "—"}
                              </div>
                            ) : (
                              <input
                                type={typeof value === 'number' ? "number" : "text"}
                                value={value ?? ""}
                                onChange={e => handleFieldEdit(fieldKey,
                                  e.target.type === "number" ? parseFloat(e.target.value) || "" : e.target.value
                                )}
                                style={{
                                  width: "100%", padding: "6px 0",
                                  background: "transparent", border: "none",
                                  borderBottom: "1px solid rgba(255,255,255,0.08)",
                                  color: value !== undefined && value !== "" ? "#C4F53A" : "#4A4A4A",
                                  fontFamily: "'JetBrains Mono', monospace",
                                  fontSize: "1rem", fontWeight: 500,
                                }}
                                placeholder="—"
                              />
                            )}
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}

        {/* ===== TAB 3: DB MAPPING ===== */}
        {activeTab === "mapping" && (
          <div style={{ animation: "slideIn 0.4s ease" }}>
            {/* Elixir Schema */}
            <div style={{
              background: "#1A1A1A", borderRadius: 16, padding: 28,
              border: "1px solid rgba(255,255,255,0.04)", marginBottom: 24,
            }}>
              <div style={{
                fontFamily: "'Bebas Neue', sans-serif", fontSize: "1.3rem",
                letterSpacing: 1, marginBottom: 6,
                display: "flex", alignItems: "center", gap: 10,
              }}>
                <span>🗄️</span> SCHEMA ELIXIR — ANOVATOR_ASSESSMENTS
              </div>
              <div style={{
                fontSize: "0.75rem", color: "#8A8A8A", marginBottom: 20,
              }}>
                Tabela dedicada para armazenar dados da bioimpedância Anovator
              </div>
              
              <pre style={{
                background: "#0A0A0A", borderRadius: 12, padding: 24,
                fontFamily: "'JetBrains Mono', monospace", fontSize: "0.78rem",
                lineHeight: 1.7, overflow: "auto", maxHeight: 500,
                border: "1px solid rgba(255,255,255,0.04)",
                color: "#C4C4C4",
              }}>{`defmodule GaPersonal.Evolution.AnovatorAssessment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "anovator_assessments" do
    belongs_to :student, GaPersonal.Accounts.User
    belongs_to :trainer, GaPersonal.Accounts.User

    field :assessed_at, :date
    field :anovator_url, :string
    field :anovator_report_id, :string

    # === Composição Corporal ===
    field :weight, :decimal
    field :fat_weight, :decimal
    field :muscle_weight, :decimal
    field :body_fat_percentage, :decimal
    field :bmi, :decimal
    field :bmr, :integer
    field :body_water, :decimal
    field :protein, :decimal
    field :bone_mass, :decimal
    field :visceral_fat, :integer
    field :body_age, :integer
    field :lean_mass, :decimal

    # === Segmentar Músculos (kg) ===
    field :muscle_right_arm, :decimal
    field :muscle_left_arm, :decimal
    field :muscle_trunk, :decimal
    field :muscle_right_leg, :decimal
    field :muscle_left_leg, :decimal
    # Rates (% do ideal)
    field :muscle_right_arm_rate, :decimal
    field :muscle_left_arm_rate, :decimal
    field :muscle_trunk_rate, :decimal
    field :muscle_right_leg_rate, :decimal
    field :muscle_left_leg_rate, :decimal

    # === Segmentar Gordura (kg) ===
    field :fat_right_arm, :decimal
    field :fat_left_arm, :decimal
    field :fat_trunk, :decimal
    field :fat_right_leg, :decimal
    field :fat_left_leg, :decimal
    # Rates
    field :fat_right_arm_rate, :decimal
    field :fat_left_arm_rate, :decimal
    field :fat_trunk_rate, :decimal
    field :fat_right_leg_rate, :decimal
    field :fat_left_leg_rate, :decimal

    # === Dimensões Corporais (cm) ===
    field :shoulder_width, :decimal
    field :chest, :decimal
    field :waist, :decimal
    field :hip, :decimal
    field :right_arm_circ, :decimal
    field :left_arm_circ, :decimal
    field :right_thigh, :decimal
    field :left_thigh, :decimal
    field :right_calf, :decimal
    field :left_calf, :decimal

    # === Análise Postural ===
    field :shoulder_diff, :decimal
    field :shoulder_risk, :string
    field :spine_risk, :string
    field :spine_diff, :decimal
    field :head_angle, :decimal
    field :head_risk, :string
    field :humpback_angle, :decimal
    field :humpback_risk, :string
    field :pelvis_angle, :decimal
    field :pelvis_risk, :string
    field :knee_angle, :decimal
    field :knee_risk, :string
    field :head_lead_angle, :decimal
    field :front_head_risk, :string

    # === Performance & Saúde ===
    field :resting_heart_rate, :integer
    field :heart_function, :string
    field :systolic_bp, :integer
    field :diastolic_bp, :integer
    field :sport_safety, :string
    field :balance_angle, :decimal
    field :balance_rating, :string
    field :vital_capacity, :integer
    field :reaction_time, :integer

    # === Plano ===
    field :sport_goal, :integer
    field :aerobic_goal, :integer
    field :endurance_goal, :integer
    field :anaerobic_goal, :integer
    field :calories_input, :integer
    field :body_shape_index, :integer
    field :predictive_height, :decimal

    # === Raw JSON (backup completo) ===
    field :raw_data, :map

    timestamps()
  end

  @required_fields [:student_id, :assessed_at, :weight]
  @optional_fields [
    :trainer_id, :anovator_url, :anovator_report_id,
    :fat_weight, :muscle_weight, :body_fat_percentage,
    :bmi, :bmr, :body_water, :protein, :bone_mass,
    :visceral_fat, :body_age, :lean_mass,
    :muscle_right_arm, :muscle_left_arm, :muscle_trunk,
    :muscle_right_leg, :muscle_left_leg,
    :muscle_right_arm_rate, :muscle_left_arm_rate,
    :muscle_trunk_rate, :muscle_right_leg_rate,
    :muscle_left_leg_rate,
    :fat_right_arm, :fat_left_arm, :fat_trunk,
    :fat_right_leg, :fat_left_leg,
    :fat_right_arm_rate, :fat_left_arm_rate,
    :fat_trunk_rate, :fat_right_leg_rate,
    :fat_left_leg_rate,
    :shoulder_width, :chest, :waist, :hip,
    :right_arm_circ, :left_arm_circ,
    :right_thigh, :left_thigh, :right_calf, :left_calf,
    :shoulder_diff, :shoulder_risk, :spine_risk,
    :spine_diff, :head_angle, :head_risk,
    :humpback_angle, :humpback_risk,
    :pelvis_angle, :pelvis_risk,
    :knee_angle, :knee_risk,
    :head_lead_angle, :front_head_risk,
    :resting_heart_rate, :heart_function,
    :systolic_bp, :diastolic_bp, :sport_safety,
    :balance_angle, :balance_rating,
    :vital_capacity, :reaction_time,
    :sport_goal, :aerobic_goal, :endurance_goal,
    :anaerobic_goal, :calories_input,
    :body_shape_index, :predictive_height, :raw_data
  ]

  def changeset(assessment, attrs) do
    assessment
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:weight, greater_than: 0)
    |> validate_number(:body_fat_percentage,
         greater_than_or_equal_to: 0,
         less_than_or_equal_to: 70)
    |> foreign_key_constraint(:student_id)
    |> foreign_key_constraint(:trainer_id)
  end
end`}</pre>
            </div>

            {/* Phoenix Controller */}
            <div style={{
              background: "#1A1A1A", borderRadius: 16, padding: 28,
              border: "1px solid rgba(255,255,255,0.04)", marginBottom: 24,
            }}>
              <div style={{
                fontFamily: "'Bebas Neue', sans-serif", fontSize: "1.3rem",
                letterSpacing: 1, marginBottom: 6,
                display: "flex", alignItems: "center", gap: 10,
              }}>
                <span>⚡</span> SERVIÇO DE SCRAPING — ANOVATOR PARSER
              </div>
              
              <pre style={{
                background: "#0A0A0A", borderRadius: 12, padding: 24,
                fontFamily: "'JetBrains Mono', monospace", fontSize: "0.78rem",
                lineHeight: 1.7, overflow: "auto", maxHeight: 400,
                border: "1px solid rgba(255,255,255,0.04)",
                color: "#C4C4C4",
              }}>{`defmodule GaPersonal.Evolution.AnovatorParser do
  @moduledoc """
  Serviço para extrair dados do relatório Anovator.
  
  A página da Anovator (mobile8.0.html) é uma SPA Vue.js que
  carrega dados via API interna usando o parâmetro 'id' da URL.
  
  Estratégias de extração:
  1. API direta: GET anovator.com/api/exam/{id} (se disponível)
  2. Headless browser: Renderiza a página e extrai o objeto 'exam'
  3. Manual: Recebe JSON colado pelo aluno/personal
  """

  require Logger

  @anovator_base "https://www.anovator.com"

  @doc """
  Extrai o ID do exame a partir da URL do relatório.
  URL format: /body/mobile8.0.html?id=013378750624220&lang=pt_PT
  """
  def extract_report_id(url) when is_binary(url) do
    uri = URI.parse(url)
    query = URI.decode_query(uri.query || "")

    case Map.get(query, "id") do
      nil -> {:error, :id_not_found}
      id -> {:ok, id}
    end
  end

  @doc """
  Tenta buscar dados via API direta da Anovator.
  Primeiro tenta o endpoint da API, depois fallback para scraping.
  """
  def fetch_exam_data(url) do
    with {:ok, report_id} <- extract_report_id(url) do
      case try_api_fetch(report_id) do
        {:ok, data} -> {:ok, data}
        {:error, _} -> try_headless_fetch(url)
      end
    end
  end

  # Tenta buscar via API REST (endpoint inferido)
  defp try_api_fetch(report_id) do
    api_url = "\#{@anovator_base}/api/report/\#{report_id}"

    case Req.get(api_url, headers: [{"accept", "application/json"}]) do
      {:ok, %{status: 200, body: body}} when is_map(body) ->
        {:ok, normalize_exam_data(body)}
      _ ->
        {:error, :api_not_available}
    end
  end

  # Fallback: usa headless browser para renderizar e extrair
  defp try_headless_fetch(url) do
    # Usa ChromicPDF ou Wallaby para renderizar a página
    # e executar JS para extrair o objeto exam da instância Vue
    script = """
    const app = document.querySelector('#app').__vue_app__;
    const vm = app._instance.proxy;
    return JSON.stringify(vm.exam);
    """

    case GaPersonal.Browser.evaluate(url, script) do
      {:ok, json_str} ->
        {:ok, json_str |> Jason.decode!() |> normalize_exam_data()}
      {:error, reason} ->
        Logger.warning("Headless fetch failed: \#{reason}")
        {:error, :headless_failed}
    end
  end

  @doc """
  Normaliza os dados do exam para o formato do nosso schema.
  Mapeia cada campo Anovator → campo do banco GA Personal.
  """
  def normalize_exam_data(raw) do
    %{
      # Composição corporal
      weight: get_decimal(raw, "weight"),
      fat_weight: get_decimal(raw, "fatWeight"),
      muscle_weight: get_decimal(raw, "muscleWeight"),
      body_fat_percentage: get_decimal(raw, "bodyFatRate"),
      bmi: get_decimal(raw, "bmi"),
      bmr: get_integer(raw, "bmr"),
      body_water: get_decimal(raw, "bodyWater"),
      protein: get_decimal(raw, "protein"),
      bone_mass: get_decimal(raw, "boneMass"),
      visceral_fat: get_integer(raw, "visceralFat"),
      body_age: get_integer(raw, "bodyAge"),
      lean_mass: get_decimal(raw, "leanMass"),

      # Segmentar - Músculos
      muscle_right_arm: get_decimal(raw, "muscleRightArm"),
      muscle_left_arm: get_decimal(raw, "muscleLeftArm"),
      muscle_trunk: get_decimal(raw, "muscleTrunk"),
      muscle_right_leg: get_decimal(raw, "muscleRightLeg"),
      muscle_left_leg: get_decimal(raw, "muscleLeftLeg"),

      # ... (todos os demais campos seguem o mesmo padrão)

      # Raw data backup
      raw_data: raw
    }
  end

  defp get_decimal(map, key) do
    case Map.get(map, key) do
      nil -> nil
      val when is_number(val) -> Decimal.from_float(val / 1)
      val when is_binary(val) -> Decimal.new(val)
      _ -> nil
    end
  end

  defp get_integer(map, key) do
    case Map.get(map, key) do
      nil -> nil
      val when is_integer(val) -> val
      val when is_float(val) -> round(val)
      val when is_binary(val) -> String.to_integer(val)
      _ -> nil
    end
  end
end`}</pre>
            </div>

            {/* API Payload Preview */}
            {importedData && (
              <div style={{
                background: "#1A1A1A", borderRadius: 16, padding: 28,
                border: "1px solid rgba(255,255,255,0.04)", marginBottom: 24,
              }}>
                <div style={{
                  fontFamily: "'Bebas Neue', sans-serif", fontSize: "1.3rem",
                  letterSpacing: 1, marginBottom: 6,
                  display: "flex", alignItems: "center", gap: 10,
                }}>
                  <span>📡</span> PAYLOAD DA API (PREVIEW)
                </div>
                <div style={{
                  fontSize: "0.75rem", color: "#8A8A8A", marginBottom: 16,
                }}>
                  POST /api/v1/students/{"{student_id}"}/anovator-assessments
                </div>
                
                <pre style={{
                  background: "#0A0A0A", borderRadius: 12, padding: 24,
                  fontFamily: "'JetBrains Mono', monospace", fontSize: "0.75rem",
                  lineHeight: 1.6, overflow: "auto", maxHeight: 300,
                  border: "1px solid rgba(255,255,255,0.04)",
                  color: "#C4F53A",
                }}>
                  {JSON.stringify(generateApiPayload(), null, 2)}
                </pre>
              </div>
            )}

            {/* Migration */}
            <div style={{
              background: "#1A1A1A", borderRadius: 16, padding: 28,
              border: "1px solid rgba(255,255,255,0.04)",
            }}>
              <div style={{
                fontFamily: "'Bebas Neue', sans-serif", fontSize: "1.3rem",
                letterSpacing: 1, marginBottom: 6,
                display: "flex", alignItems: "center", gap: 10,
              }}>
                <span>🔄</span> MIGRATION POSTGRESQL
              </div>
              
              <pre style={{
                background: "#0A0A0A", borderRadius: 12, padding: 24,
                fontFamily: "'JetBrains Mono', monospace", fontSize: "0.78rem",
                lineHeight: 1.7, overflow: "auto", maxHeight: 400,
                border: "1px solid rgba(255,255,255,0.04)",
                color: "#C4C4C4",
              }}>{`defmodule GaPersonal.Repo.Migrations.CreateAnovatorAssessments do
  use Ecto.Migration

  def change do
    create table(:anovator_assessments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :student_id, references(:users, type: :binary_id,
            on_delete: :delete_all), null: false
      add :trainer_id, references(:users, type: :binary_id)
      add :assessed_at, :date, null: false
      add :anovator_url, :text
      add :anovator_report_id, :string

      # Composição Corporal
      add :weight, :decimal, precision: 5, scale: 2
      add :fat_weight, :decimal, precision: 5, scale: 2
      add :muscle_weight, :decimal, precision: 5, scale: 2
      add :body_fat_percentage, :decimal, precision: 4, scale: 1
      add :bmi, :decimal, precision: 4, scale: 1
      add :bmr, :integer
      add :body_water, :decimal, precision: 4, scale: 1
      add :protein, :decimal, precision: 5, scale: 2
      add :bone_mass, :decimal, precision: 4, scale: 2
      add :visceral_fat, :integer
      add :body_age, :integer
      add :lean_mass, :decimal, precision: 5, scale: 2

      # Análise Segmentar — Músculos
      add :muscle_right_arm, :decimal, precision: 5, scale: 2
      add :muscle_left_arm, :decimal, precision: 5, scale: 2
      add :muscle_trunk, :decimal, precision: 5, scale: 2
      add :muscle_right_leg, :decimal, precision: 5, scale: 2
      add :muscle_left_leg, :decimal, precision: 5, scale: 2
      add :muscle_right_arm_rate, :decimal, precision: 5, scale: 1
      add :muscle_left_arm_rate, :decimal, precision: 5, scale: 1
      add :muscle_trunk_rate, :decimal, precision: 5, scale: 1
      add :muscle_right_leg_rate, :decimal, precision: 5, scale: 1
      add :muscle_left_leg_rate, :decimal, precision: 5, scale: 1

      # Análise Segmentar — Gordura
      add :fat_right_arm, :decimal, precision: 5, scale: 2
      add :fat_left_arm, :decimal, precision: 5, scale: 2
      add :fat_trunk, :decimal, precision: 5, scale: 2
      add :fat_right_leg, :decimal, precision: 5, scale: 2
      add :fat_left_leg, :decimal, precision: 5, scale: 2
      add :fat_right_arm_rate, :decimal, precision: 5, scale: 1
      add :fat_left_arm_rate, :decimal, precision: 5, scale: 1
      add :fat_trunk_rate, :decimal, precision: 5, scale: 1
      add :fat_right_leg_rate, :decimal, precision: 5, scale: 1
      add :fat_left_leg_rate, :decimal, precision: 5, scale: 1

      # Dimensões Corporais (cm)
      add :shoulder_width, :decimal, precision: 5, scale: 1
      add :chest, :decimal, precision: 5, scale: 1
      add :waist, :decimal, precision: 5, scale: 1
      add :hip, :decimal, precision: 5, scale: 1
      add :right_arm_circ, :decimal, precision: 5, scale: 1
      add :left_arm_circ, :decimal, precision: 5, scale: 1
      add :right_thigh, :decimal, precision: 5, scale: 1
      add :left_thigh, :decimal, precision: 5, scale: 1
      add :right_calf, :decimal, precision: 5, scale: 1
      add :left_calf, :decimal, precision: 5, scale: 1

      # Análise Postural
      add :shoulder_diff, :decimal, precision: 4, scale: 1
      add :shoulder_risk, :string
      add :spine_risk, :string
      add :spine_diff, :decimal, precision: 4, scale: 1
      add :head_angle, :decimal, precision: 4, scale: 1
      add :head_risk, :string
      add :humpback_angle, :decimal, precision: 4, scale: 1
      add :humpback_risk, :string
      add :pelvis_angle, :decimal, precision: 4, scale: 1
      add :pelvis_risk, :string
      add :knee_angle, :decimal, precision: 4, scale: 1
      add :knee_risk, :string
      add :head_lead_angle, :decimal, precision: 4, scale: 1
      add :front_head_risk, :string

      # Performance & Saúde
      add :resting_heart_rate, :integer
      add :heart_function, :string
      add :systolic_bp, :integer
      add :diastolic_bp, :integer
      add :sport_safety, :string
      add :balance_angle, :decimal, precision: 4, scale: 1
      add :balance_rating, :string
      add :vital_capacity, :integer
      add :reaction_time, :integer

      # Plano
      add :sport_goal, :integer
      add :aerobic_goal, :integer
      add :endurance_goal, :integer
      add :anaerobic_goal, :integer
      add :calories_input, :integer
      add :body_shape_index, :integer
      add :predictive_height, :decimal, precision: 5, scale: 1

      # Raw JSON backup
      add :raw_data, :map

      timestamps()
    end

    create index(:anovator_assessments, [:student_id])
    create index(:anovator_assessments, [:assessed_at])
    create index(:anovator_assessments, [:student_id, :assessed_at])
    create unique_index(:anovator_assessments, [:anovator_report_id])
  end
end`}</pre>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
