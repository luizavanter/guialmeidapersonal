import { useState, useEffect, useRef, useCallback } from "react";

// ============================================================
// GA PERSONAL — Sistema Completo
// 1. Ficha de Evolução do Aluno (manual + Anovator + Relaxmedic)
// 2. Página de Planos & Valores
// 3. Cadastro do Potencial Aluno
// 4. Painel Admin do Guilherme
//
// Aparelhos suportados:
// - Anovator M0/M1/M3/A5 (link direto / headless scraping)
// - Relaxmedic Intelligence Plus RM-BD0914A (app RelaxFIT / PDF)
// - InBody, Tanita, Omron (entrada manual)
// - Qualquer outro (entrada manual genérica)
// ============================================================

const PAGES = {
  HOME: "home",
  PLANS: "plans",
  REGISTER: "register",
  STUDENT_PORTAL: "student_portal",
  STUDENT_EVOLUTION: "student_evolution",
  ADMIN: "admin",
  ADMIN_SITE: "admin_site",
  ADMIN_STUDENTS: "admin_students",
  ADMIN_STUDENT_DETAIL: "admin_student_detail",
};

// Brand colors
const C = {
  coal: "#0A0A0A", graphite: "#1A1A1A", steel: "#2A2A2A",
  smoke: "#8A8A8A", fog: "#C4C4C4", white: "#F5F5F0",
  accent: "#C4F53A", accentDim: "#9BC22E", ocean: "#0EA5E9",
  oceanDeep: "#0369A1", warm: "#F59E0B", coral: "#EF4444",
  green: "#22C55E", purple: "#A855F7",
};

// Fonts CSS
const fontCSS = `@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Outfit:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500&display=swap');`;

// Reusable styles
const S = {
  fontDisplay: "'Bebas Neue', sans-serif",
  fontBody: "'Outfit', sans-serif",
  fontMono: "'JetBrains Mono', monospace",
};

// ===== MOCK DATA =====
const PLANS_DATA = [
  {
    id: 1, name: "Essencial", price: 450, period: "mês", sessions: 2, popular: false,
    color: C.ocean, features: [
      "2 sessões por semana", "Planilha de treino personalizada", "Acompanhamento via app",
      "Reavaliação mensal", "Suporte via WhatsApp",
    ],
  },
  {
    id: 2, name: "Performance", price: 750, period: "mês", sessions: 3, popular: true,
    color: C.accent, features: [
      "3 sessões por semana", "Planilha de treino + periodização", "Acompanhamento via app",
      "Avaliação física quinzenal", "Bioimpedância mensal (Anovator/Relaxmedic)", "Suporte prioritário WhatsApp",
      "Orientação nutricional básica",
    ],
  },
  {
    id: 3, name: "Elite", price: 1200, period: "mês", sessions: 5, popular: false,
    color: C.purple, features: [
      "5 sessões por semana", "Periodização completa (meso/micro ciclos)", "Acompanhamento via app",
      "Avaliação física semanal", "Bioimpedância quinzenal (Anovator/Relaxmedic)", "Suporte 24h WhatsApp",
      "Orientação nutricional completa", "Fotos comparativas mensais", "Relatório mensal de evolução",
    ],
  },
];

const TRAINING_TYPES = [
  { icon: "🔥", name: "Emagrecimento", desc: "Queima de gordura com treinos HIIT, circuitos metabólicos e controle de composição corporal.", color: C.coral },
  { icon: "💪", name: "Hipertrofia", desc: "Ganho de massa muscular com periodização inteligente e progressão de cargas monitorada.", color: C.ocean },
  { icon: "⚡", name: "Hybrid Training", desc: "Combinação de força e condicionamento para performance completa — forte, resistente e ágil.", color: C.accent },
  { icon: "🧘", name: "Funcional", desc: "Melhora da mobilidade, equilíbrio e capacidade funcional para o dia a dia e qualidade de vida.", color: C.warm },
  { icon: "👴", name: "Melhor Idade", desc: "Programa especial 60+ com foco em força, equilíbrio, prevenção de quedas e autonomia.", color: C.green },
  { icon: "🏃", name: "Prep. Esportiva", desc: "Condicionamento específico para corrida, surf, ciclismo, futebol e outros esportes.", color: C.purple },
];

const MOCK_STUDENTS = [
  { id: 1, name: "Ana Carolina Martins", email: "ana@email.com", phone: "(48) 99123-4567", objective: "Emagrecimento", plan: "Performance", status: "active", avatar: "AC", startDate: "2025-09-15", lastSession: "2026-02-01", sessions: 58 },
  { id: 2, name: "Roberto Santos Filho", email: "roberto@email.com", phone: "(48) 99234-5678", objective: "Hipertrofia", plan: "Elite", status: "active", avatar: "RS", startDate: "2025-06-01", lastSession: "2026-02-03", sessions: 112 },
  { id: 3, name: "Mariana Kowalski", email: "mari@email.com", phone: "(48) 99345-6789", objective: "Hybrid Training", plan: "Performance", status: "active", avatar: "MK", startDate: "2025-11-01", lastSession: "2026-02-02", sessions: 34 },
  { id: 4, name: "Carlos Eduardo Lima", email: "carlos@email.com", phone: "(48) 99456-7890", objective: "Funcional", plan: "Essencial", status: "active", avatar: "CE", startDate: "2024-03-10", lastSession: "2026-01-30", sessions: 198 },
  { id: 5, name: "Juliana Rodrigues", email: "juliana@email.com", phone: "(48) 99567-8901", objective: "Emagrecimento", plan: "Performance", status: "paused", avatar: "JR", startDate: "2025-08-20", lastSession: "2026-01-15", sessions: 44 },
  { id: 6, name: "Pedro Henrique Souza", email: "pedro@email.com", phone: "(48) 99678-9012", objective: "Hipertrofia", plan: "Elite", status: "active", avatar: "PH", startDate: "2025-04-01", lastSession: "2026-02-03", sessions: 156 },
  { id: 7, name: "Beatriz Ferreira", email: "bia@email.com", phone: "(48) 99789-0123", objective: "Melhor Idade", plan: "Essencial", status: "active", avatar: "BF", startDate: "2025-01-15", lastSession: "2026-02-01", sessions: 89 },
  { id: 8, name: "Lucas Andrade", email: "lucas@email.com", phone: "(48) 99890-1234", objective: "Hybrid Training", plan: "Performance", status: "lead", avatar: "LA", startDate: null, lastSession: null, sessions: 0 },
];

const MOCK_EVOLUTION_HISTORY = [
  { id: 1, date: "2026-02-01", source: "anovator", weight: 78.2, bodyFat: 21.3, muscleMass: 34.8, bmi: 24.5, waist: 86, chest: 100, rightArm: 35.2, notes: "", fatMass: null, boneMass: null, bodyWater: null, visceralFat: null, bmr: null, protein: null, bodyAge: null, subFat: null, fatFreeWeight: null, skeletalMuscle: null, muscleRate: null, idealWeight: null, obesityLevel: null, muscleRightArm: null, muscleLeftArm: null, muscleRightLeg: null, muscleLeftLeg: null, fatRightLeg: null, fatLeftLeg: null },
  { id: 2, date: "2026-01-20", source: "relaxmedic", weight: 78.8, bodyFat: 21.8, muscleMass: 34.6, bmi: 24.7, waist: null, chest: null, rightArm: null, notes: "Medido em casa — RelaxFIT app", fatMass: 17.2, boneMass: 3.0, bodyWater: 55.1, visceralFat: 8, bmr: 1755, protein: 18.2, bodyAge: 33, subFat: 19.5, fatFreeWeight: 61.6, skeletalMuscle: 31.2, muscleRate: 44.1, idealWeight: 72.0, obesityLevel: "Normal", muscleRightArm: 2.1, muscleLeftArm: 2.0, muscleRightLeg: 9.4, muscleLeftLeg: 9.2, fatRightLeg: 3.1, fatLeftLeg: 3.0 },
  { id: 3, date: "2026-01-15", source: "manual", weight: 79.1, bodyFat: 22.0, muscleMass: 34.5, bmi: 24.8, waist: 87, chest: 100, rightArm: 34.8, notes: "Medido na balança da academia", fatMass: null, boneMass: null, bodyWater: null, visceralFat: null, bmr: null, protein: null, bodyAge: null, subFat: null, fatFreeWeight: null, skeletalMuscle: null, muscleRate: null, idealWeight: null, obesityLevel: null, muscleRightArm: null, muscleLeftArm: null, muscleRightLeg: null, muscleLeftLeg: null, fatRightLeg: null, fatLeftLeg: null },
  { id: 4, date: "2026-01-01", source: "anovator", weight: 80.5, bodyFat: 23.1, muscleMass: 34.0, bmi: 25.2, waist: 89, chest: 99, rightArm: 34.5, notes: "", fatMass: null, boneMass: null, bodyWater: null, visceralFat: null, bmr: null, protein: null, bodyAge: null, subFat: null, fatFreeWeight: null, skeletalMuscle: null, muscleRate: null, idealWeight: null, obesityLevel: null, muscleRightArm: null, muscleLeftArm: null, muscleRightLeg: null, muscleLeftLeg: null, fatRightLeg: null, fatLeftLeg: null },
  { id: 5, date: "2025-12-15", source: "relaxmedic", weight: 81.2, bodyFat: 23.8, muscleMass: 33.5, bmi: 25.4, waist: null, chest: null, rightArm: null, notes: "Primeira medição em casa", fatMass: 19.3, boneMass: 2.9, bodyWater: 53.2, visceralFat: 9, bmr: 1720, protein: 17.5, bodyAge: 35, subFat: 21.2, fatFreeWeight: 61.9, skeletalMuscle: 30.5, muscleRate: 43.2, idealWeight: 72.0, obesityLevel: "Sobrepeso leve", muscleRightArm: 2.0, muscleLeftArm: 1.9, muscleRightLeg: 9.1, muscleLeftLeg: 8.9, fatRightLeg: 3.4, fatLeftLeg: 3.3 },
  { id: 6, date: "2025-12-01", source: "anovator", weight: 82.5, bodyFat: 24.5, muscleMass: 33.2, bmi: 25.8, waist: 92, chest: 98, rightArm: 33.8, notes: "Avaliação inicial", fatMass: null, boneMass: null, bodyWater: null, visceralFat: null, bmr: null, protein: null, bodyAge: null, subFat: null, fatFreeWeight: null, skeletalMuscle: null, muscleRate: null, idealWeight: null, obesityLevel: null, muscleRightArm: null, muscleLeftArm: null, muscleRightLeg: null, muscleLeftLeg: null, fatRightLeg: null, fatLeftLeg: null },
];

// === Device field mapping — what each source measures ===
const DEVICE_FIELDS = {
  anovator: {
    name: "Anovator (M0/M1/M3/A5)",
    icon: "🔬",
    color: "#0EA5E9",
    inputMethod: "Link do relatório ou manual",
    fields: ["weight","bodyFat","muscleMass","bmi","bmr","bodyWater","protein","boneMass","visceralFat","bodyAge","fatMass","fatFreeWeight","skeletalMuscle","muscleRate","muscleRightArm","muscleLeftArm","muscleRightLeg","muscleLeftLeg","fatRightLeg","fatLeftLeg","waist","chest","rightArm","leftArm","rightThigh","leftThigh"],
  },
  relaxmedic: {
    name: "Relaxmedic Intelligence Plus",
    icon: "⚖️",
    color: "#A855F7",
    inputMethod: "App RelaxFIT (Bluetooth) ou PDF",
    fields: ["weight","bodyFat","muscleMass","bmi","bmr","bodyWater","protein","boneMass","visceralFat","bodyAge","fatMass","subFat","fatFreeWeight","skeletalMuscle","muscleRate","idealWeight","obesityLevel","muscleRightArm","muscleLeftArm","muscleRightLeg","muscleLeftLeg","fatRightLeg","fatLeftLeg"],
  },
  inbody: {
    name: "InBody",
    icon: "📊",
    color: "#22C55E",
    inputMethod: "App InBody ou manual",
    fields: ["weight","bodyFat","muscleMass","bmi","bmr","bodyWater","protein","boneMass","visceralFat","fatMass","fatFreeWeight","skeletalMuscle","waist"],
  },
  tanita: {
    name: "Tanita",
    icon: "📊",
    color: "#F59E0B",
    inputMethod: "Manual",
    fields: ["weight","bodyFat","muscleMass","bmi","bmr","bodyWater","boneMass","visceralFat"],
  },
  omron: {
    name: "Omron",
    icon: "📊",
    color: "#EF4444",
    inputMethod: "App OMRON Connect ou manual",
    fields: ["weight","bodyFat","muscleMass","bmi","bmr","visceralFat","skeletalMuscle"],
  },
  manual: {
    name: "Entrada manual",
    icon: "✏️",
    color: "#F59E0B",
    inputMethod: "Balança simples, fita métrica, etc.",
    fields: ["weight","bodyFat","muscleMass","bmi","waist","chest","rightArm","leftArm","rightThigh","leftThigh"],
  },
  outro: {
    name: "Outro aparelho",
    icon: "📋",
    color: "#8A8A8A",
    inputMethod: "Entrada manual genérica",
    fields: ["weight","bodyFat","muscleMass","bmi","bmr","bodyWater","protein","boneMass","visceralFat","bodyAge","fatMass","subFat","fatFreeWeight","skeletalMuscle","muscleRate","idealWeight","obesityLevel","muscleRightArm","muscleLeftArm","muscleRightLeg","muscleLeftLeg","fatRightLeg","fatLeftLeg","waist","chest","rightArm","leftArm","rightThigh","leftThigh"],
  },
};

// All possible measurement fields with labels
const ALL_MEASUREMENT_FIELDS = {
  // Composição básica
  weight: { label: "Peso", unit: "kg", group: "basic" },
  bodyFat: { label: "Gordura Corporal", unit: "%", group: "basic" },
  muscleMass: { label: "Massa Muscular", unit: "kg", group: "basic" },
  bmi: { label: "IMC", unit: "", group: "basic" },
  bmr: { label: "Taxa Metab. Basal", unit: "kcal", group: "basic" },
  bodyAge: { label: "Idade Corporal", unit: "anos", group: "basic" },
  // Composição avançada
  bodyWater: { label: "Água Corporal", unit: "%", group: "advanced" },
  protein: { label: "Taxa de Proteína", unit: "%", group: "advanced" },
  boneMass: { label: "Massa Óssea", unit: "kg", group: "advanced" },
  visceralFat: { label: "Gordura Visceral", unit: "", group: "advanced" },
  fatMass: { label: "Massa Gorda", unit: "kg", group: "advanced" },
  subFat: { label: "Gordura Subcutânea", unit: "%", group: "advanced" },
  fatFreeWeight: { label: "Peso Livre de Gordura", unit: "kg", group: "advanced" },
  skeletalMuscle: { label: "Músculo Esquelético", unit: "kg", group: "advanced" },
  muscleRate: { label: "Taxa Muscular", unit: "%", group: "advanced" },
  idealWeight: { label: "Peso Ideal", unit: "kg", group: "advanced" },
  obesityLevel: { label: "Nível Obesidade", unit: "", group: "advanced", isText: true },
  // Segmentar
  muscleRightArm: { label: "Musc. Braço Dir.", unit: "kg", group: "segmental" },
  muscleLeftArm: { label: "Musc. Braço Esq.", unit: "kg", group: "segmental" },
  muscleRightLeg: { label: "Musc. Perna Dir.", unit: "kg", group: "segmental" },
  muscleLeftLeg: { label: "Musc. Perna Esq.", unit: "kg", group: "segmental" },
  fatRightLeg: { label: "Gord. Perna Dir.", unit: "%", group: "segmental" },
  fatLeftLeg: { label: "Gord. Perna Esq.", unit: "%", group: "segmental" },
  // Medidas corporais
  waist: { label: "Cintura", unit: "cm", group: "measurements" },
  chest: { label: "Peito", unit: "cm", group: "measurements" },
  rightArm: { label: "Braço Dir.", unit: "cm", group: "measurements" },
  leftArm: { label: "Braço Esq.", unit: "cm", group: "measurements" },
  rightThigh: { label: "Coxa Dir.", unit: "cm", group: "measurements" },
  leftThigh: { label: "Coxa Esq.", unit: "cm", group: "measurements" },
};

// ===== REUSABLE COMPONENTS =====

function LogoMark({ size = 40 }) {
  return (
    <div style={{
      width: size, height: size, background: C.accent, borderRadius: size * 0.25,
      display: "flex", alignItems: "center", justifyContent: "center",
      fontFamily: S.fontDisplay, fontSize: size * 0.38, color: C.coal,
      transform: "rotate(-3deg)", flexShrink: 0,
    }}>GA</div>
  );
}

function Btn({ children, variant = "primary", onClick, disabled, full, style: extraStyle }) {
  const base = {
    padding: "12px 24px", border: "none", borderRadius: 10, fontWeight: 700,
    fontSize: "0.85rem", cursor: disabled ? "not-allowed" : "pointer",
    fontFamily: S.fontBody, letterSpacing: 0.5, transition: "all 0.3s ease",
    display: "inline-flex", alignItems: "center", gap: 8,
    width: full ? "100%" : "auto", justifyContent: full ? "center" : "flex-start",
    opacity: disabled ? 0.5 : 1,
  };
  const variants = {
    primary: { ...base, background: C.accent, color: C.coal },
    outline: { ...base, background: "transparent", color: C.accent, border: `1.5px solid ${C.accent}44` },
    ghost: { ...base, background: "rgba(255,255,255,0.04)", color: C.fog, border: `1px solid rgba(255,255,255,0.06)` },
    danger: { ...base, background: `${C.coral}22`, color: C.coral, border: `1px solid ${C.coral}33` },
    ocean: { ...base, background: C.ocean, color: C.white },
  };
  return <button onClick={onClick} disabled={disabled} style={{ ...variants[variant], ...extraStyle }}>{children}</button>;
}

function Card({ children, style: extraStyle, onClick }) {
  return (
    <div onClick={onClick} style={{
      background: C.graphite, borderRadius: 16, padding: 24,
      border: "1px solid rgba(255,255,255,0.04)", transition: "all 0.3s ease",
      cursor: onClick ? "pointer" : "default", ...extraStyle,
    }}>{children}</div>
  );
}

function SectionTag({ children }) {
  return (
    <div style={{
      fontFamily: S.fontMono, fontSize: "0.72rem", color: C.accent,
      letterSpacing: 3, textTransform: "uppercase", marginBottom: 12,
    }}>// {children}</div>
  );
}

function SectionTitle({ children }) {
  return (
    <h2 style={{
      fontFamily: S.fontDisplay, fontSize: "clamp(2rem, 4vw, 3rem)",
      lineHeight: 1, letterSpacing: -0.5, margin: 0,
    }}>{children}</h2>
  );
}

function Input({ label, type = "text", value, onChange, placeholder, required, unit, textarea, icon }) {
  const El = textarea ? "textarea" : "input";
  return (
    <div style={{ marginBottom: 16 }}>
      {label && (
        <label style={{
          display: "block", fontSize: "0.8rem", color: C.fog,
          marginBottom: 6, fontWeight: 500,
        }}>
          {icon && <span style={{ marginRight: 6 }}>{icon}</span>}
          {label} {required && <span style={{ color: C.coral }}>*</span>}
        </label>
      )}
      <div style={{ position: "relative" }}>
        <El
          type={type} value={value} onChange={e => onChange(e.target.value)}
          placeholder={placeholder} required={required}
          rows={textarea ? 3 : undefined}
          style={{
            width: "100%", padding: "12px 16px",
            paddingRight: unit ? 50 : 16,
            background: "rgba(255,255,255,0.04)",
            border: "1px solid rgba(255,255,255,0.08)", borderRadius: 10,
            color: C.white, fontFamily: S.fontBody, fontSize: "0.9rem",
            resize: textarea ? "vertical" : "none",
          }}
        />
        {unit && (
          <span style={{
            position: "absolute", right: 14, top: "50%", transform: "translateY(-50%)",
            fontSize: "0.75rem", color: C.smoke, fontFamily: S.fontMono,
          }}>{unit}</span>
        )}
      </div>
    </div>
  );
}

function Select({ label, value, onChange, options, required }) {
  return (
    <div style={{ marginBottom: 16 }}>
      {label && (
        <label style={{
          display: "block", fontSize: "0.8rem", color: C.fog,
          marginBottom: 6, fontWeight: 500,
        }}>{label} {required && <span style={{ color: C.coral }}>*</span>}</label>
      )}
      <select value={value} onChange={e => onChange(e.target.value)} style={{
        width: "100%", padding: "12px 16px",
        background: "rgba(255,255,255,0.04)",
        border: "1px solid rgba(255,255,255,0.08)", borderRadius: 10,
        color: C.white, fontFamily: S.fontBody, fontSize: "0.9rem",
        appearance: "none",
        backgroundImage: `url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath d='M6 8L1 3h10z' fill='%238A8A8A'/%3E%3C/svg%3E")`,
        backgroundRepeat: "no-repeat", backgroundPosition: "right 14px center",
      }}>
        {options.map(o => <option key={o.value} value={o.value} style={{ background: C.graphite }}>{o.label}</option>)}
      </select>
    </div>
  );
}

function StatusBadge({ status }) {
  const map = {
    active: { label: "Ativo", bg: `${C.accent}18`, color: C.accent, border: `${C.accent}33` },
    paused: { label: "Pausado", bg: `${C.warm}18`, color: C.warm, border: `${C.warm}33` },
    lead: { label: "Lead", bg: `${C.ocean}18`, color: C.ocean, border: `${C.ocean}33` },
    cancelled: { label: "Cancelado", bg: `${C.coral}18`, color: C.coral, border: `${C.coral}33` },
  };
  const s = map[status] || map.active;
  return (
    <span style={{
      fontSize: "0.7rem", padding: "3px 10px", borderRadius: 100,
      background: s.bg, color: s.color, border: `1px solid ${s.border}`,
      fontWeight: 600, letterSpacing: 0.5,
    }}>{s.label}</span>
  );
}

function SourceBadge({ source }) {
  const device = DEVICE_FIELDS[source] || DEVICE_FIELDS.outro;
  return (
    <span style={{
      fontSize: "0.65rem", padding: "2px 8px", borderRadius: 6,
      background: `${device.color}15`,
      color: device.color,
      border: `1px solid ${device.color}30`,
      fontWeight: 600, fontFamily: S.fontMono, letterSpacing: 0.5,
      display: "inline-flex", alignItems: "center", gap: 4,
    }}>{device.icon} {source === "relaxmedic" ? "RELAXMEDIC" : source === "anovator" ? "ANOVATOR" : source.toUpperCase()}</span>
  );
}

// ===== NAVIGATION =====
function Navbar({ currentPage, setPage, isAdmin }) {
  return (
    <nav style={{
      position: "sticky", top: 0, zIndex: 1000,
      background: "rgba(10,10,10,0.92)", backdropFilter: "blur(20px)",
      borderBottom: "1px solid rgba(196,245,58,0.08)",
    }}>
      <div style={{
        maxWidth: 1200, margin: "0 auto", padding: "12px 24px",
        display: "flex", alignItems: "center", justifyContent: "space-between",
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, cursor: "pointer" }}
          onClick={() => setPage(isAdmin ? PAGES.ADMIN : PAGES.HOME)}>
          <LogoMark size={36} />
          <div>
            <div style={{ fontFamily: S.fontDisplay, fontSize: "1.05rem", letterSpacing: 1.5, lineHeight: 1 }}>
              {isAdmin ? <>ADMIN <span style={{ color: C.accent }}>GA</span></> : <>GUILHERME <span style={{ color: C.accent }}>ALMEIDA</span></>}
            </div>
            <div style={{ fontFamily: S.fontMono, fontSize: "0.6rem", color: C.smoke }}>
              {isAdmin ? "PAINEL DE GESTÃO" : "PERSONAL TRAINER"}
            </div>
          </div>
        </div>
        <div style={{ display: "flex", gap: 4, alignItems: "center" }}>
          {isAdmin ? (
            <>
              {[
                { page: PAGES.ADMIN, label: "Dashboard" },
                { page: PAGES.ADMIN_STUDENTS, label: "Alunos" },
                { page: PAGES.ADMIN_SITE, label: "Site" },
              ].map(n => (
                <button key={n.page} onClick={() => setPage(n.page)} style={{
                  padding: "8px 16px", borderRadius: 8, border: "none",
                  background: currentPage === n.page ? `${C.accent}15` : "transparent",
                  color: currentPage === n.page ? C.accent : C.smoke,
                  fontFamily: S.fontBody, fontSize: "0.8rem", fontWeight: 600,
                  cursor: "pointer", transition: "all 0.2s ease",
                }}>{n.label}</button>
              ))}
              <div style={{ width: 1, height: 24, background: "rgba(255,255,255,0.06)", margin: "0 8px" }} />
              <button onClick={() => setPage(PAGES.HOME)} style={{
                padding: "8px 14px", borderRadius: 8,
                background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.06)",
                color: C.smoke, fontFamily: S.fontBody, fontSize: "0.75rem",
                cursor: "pointer",
              }}>← Ver site</button>
            </>
          ) : (
            <>
              {[
                { page: PAGES.PLANS, label: "Planos" },
                { page: PAGES.REGISTER, label: "Cadastre-se" },
                { page: PAGES.STUDENT_PORTAL, label: "Portal do Aluno" },
              ].map(n => (
                <button key={n.page} onClick={() => setPage(n.page)} style={{
                  padding: "8px 16px", borderRadius: 8, border: "none",
                  background: currentPage === n.page ? `${C.accent}15` : "transparent",
                  color: currentPage === n.page ? C.accent : C.smoke,
                  fontFamily: S.fontBody, fontSize: "0.8rem", fontWeight: 600,
                  cursor: "pointer", transition: "all 0.2s ease",
                }}>{n.label}</button>
              ))}
              <Btn variant="primary" onClick={() => setPage(PAGES.ADMIN)} style={{ padding: "8px 16px", fontSize: "0.78rem" }}>
                🔐 Admin
              </Btn>
            </>
          )}
        </div>
      </div>
    </nav>
  );
}

// ===== PAGE: PLANS & PRICING =====
function PlansPage({ setPage }) {
  return (
    <div style={{ animation: "slideIn 0.5s ease" }}>
      {/* Hero */}
      <div style={{ textAlign: "center", padding: "80px 24px 40px", position: "relative" }}>
        <div style={{
          position: "absolute", top: "50%", left: "50%", transform: "translate(-50%,-50%)",
          width: 500, height: 500, background: `radial-gradient(circle, ${C.accent}08 0%, transparent 70%)`,
          borderRadius: "50%", pointerEvents: "none",
        }} />
        <SectionTag>PLANOS & VALORES</SectionTag>
        <SectionTitle>INVISTA NA SUA TRANSFORMAÇÃO</SectionTitle>
        <p style={{ color: C.smoke, fontSize: "1.05rem", fontWeight: 300, maxWidth: 550, margin: "16px auto 0", lineHeight: 1.7 }}>
          Escolha o plano ideal para o seu objetivo. Todos incluem acompanhamento personalizado e acesso ao sistema GA Personal.
        </p>
      </div>

      {/* Plans Grid */}
      <div style={{ maxWidth: 1100, margin: "0 auto", padding: "0 24px 48px", display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 24 }}>
        {PLANS_DATA.map(plan => (
          <div key={plan.id} style={{
            background: C.graphite, borderRadius: 20, padding: 0, overflow: "hidden",
            border: plan.popular ? `2px solid ${C.accent}40` : "1px solid rgba(255,255,255,0.04)",
            position: "relative", transition: "all 0.3s ease",
            transform: plan.popular ? "scale(1.03)" : "none",
          }}>
            {plan.popular && (
              <div style={{
                background: C.accent, color: C.coal, textAlign: "center",
                padding: "6px 0", fontSize: "0.72rem", fontWeight: 800,
                letterSpacing: 2, textTransform: "uppercase",
              }}>⭐ MAIS POPULAR</div>
            )}
            <div style={{ padding: "32px 28px" }}>
              <div style={{
                width: 48, height: 48, borderRadius: 14,
                background: `${plan.color}15`, border: `1px solid ${plan.color}30`,
                display: "flex", alignItems: "center", justifyContent: "center",
                fontSize: "1.3rem", marginBottom: 20,
              }}>{plan.sessions}×</div>
              <h3 style={{ fontFamily: S.fontDisplay, fontSize: "1.8rem", letterSpacing: 1, margin: "0 0 8px" }}>
                {plan.name.toUpperCase()}
              </h3>
              <div style={{ display: "flex", alignItems: "baseline", gap: 4, marginBottom: 8 }}>
                <span style={{ fontFamily: S.fontDisplay, fontSize: "3rem", color: plan.color, lineHeight: 1 }}>
                  R${plan.price}
                </span>
                <span style={{ fontSize: "0.85rem", color: C.smoke }}>/{plan.period}</span>
              </div>
              <p style={{ fontSize: "0.82rem", color: C.smoke, marginBottom: 24 }}>
                {plan.sessions} sessões por semana
              </p>
              <div style={{ borderTop: "1px solid rgba(255,255,255,0.05)", paddingTop: 20, marginBottom: 24 }}>
                {plan.features.map((f, i) => (
                  <div key={i} style={{
                    display: "flex", alignItems: "flex-start", gap: 10,
                    padding: "6px 0", fontSize: "0.85rem", color: C.fog,
                  }}>
                    <span style={{ color: plan.color, flexShrink: 0, fontSize: "0.8rem" }}>✓</span>
                    {f}
                  </div>
                ))}
              </div>
              <Btn variant={plan.popular ? "primary" : "outline"} full onClick={() => setPage(PAGES.REGISTER)}>
                Quero esse plano →
              </Btn>
            </div>
          </div>
        ))}
      </div>

      {/* Training Types */}
      <div style={{ background: C.graphite, borderTop: `1px solid rgba(255,255,255,0.03)`, borderBottom: `1px solid rgba(255,255,255,0.03)`, padding: "64px 24px" }}>
        <div style={{ maxWidth: 1100, margin: "0 auto" }}>
          <div style={{ textAlign: "center", marginBottom: 48 }}>
            <SectionTag>MODALIDADES</SectionTag>
            <SectionTitle>TIPOS DE TREINO</SectionTitle>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 20 }}>
            {TRAINING_TYPES.map((t, i) => (
              <Card key={i} style={{ padding: 28, borderLeft: `3px solid ${t.color}` }}>
                <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 12 }}>
                  <span style={{ fontSize: "1.5rem" }}>{t.icon}</span>
                  <span style={{ fontFamily: S.fontDisplay, fontSize: "1.3rem", letterSpacing: 0.5 }}>{t.name.toUpperCase()}</span>
                </div>
                <p style={{ fontSize: "0.85rem", color: C.smoke, lineHeight: 1.7 }}>{t.desc}</p>
              </Card>
            ))}
          </div>
        </div>
      </div>

      {/* CTA */}
      <div style={{ textAlign: "center", padding: "64px 24px" }}>
        <h3 style={{ fontFamily: S.fontDisplay, fontSize: "2.5rem", marginBottom: 12 }}>
          AULA EXPERIMENTAL <span style={{ color: C.accent }}>GRATUITA</span>
        </h3>
        <p style={{ color: C.smoke, marginBottom: 32, fontSize: "1rem" }}>Cadastre-se e agende sua primeira aula sem compromisso.</p>
        <Btn onClick={() => setPage(PAGES.REGISTER)}>Cadastrar agora →</Btn>
      </div>
    </div>
  );
}

// ===== PAGE: STUDENT REGISTRATION =====
function RegisterPage({ setPage }) {
  const [form, setForm] = useState({
    name: "", email: "", phone: "", birthDate: "", objective: "", plan: "",
    healthNotes: "", howFound: "", message: "",
  });
  const [submitted, setSubmitted] = useState(false);
  const [step, setStep] = useState(1);
  const update = (k, v) => setForm(p => ({ ...p, [k]: v }));

  if (submitted) {
    return (
      <div style={{ minHeight: "70vh", display: "flex", alignItems: "center", justifyContent: "center", padding: 24 }}>
        <Card style={{ maxWidth: 520, textAlign: "center", padding: 48 }}>
          <div style={{ fontSize: "4rem", marginBottom: 16, animation: "checkmark 0.5s ease" }}>✅</div>
          <h2 style={{ fontFamily: S.fontDisplay, fontSize: "2rem", marginBottom: 8 }}>CADASTRO REALIZADO!</h2>
          <p style={{ color: C.smoke, fontSize: "0.95rem", lineHeight: 1.7, marginBottom: 32 }}>
            Oi <strong style={{ color: C.white }}>{form.name.split(" ")[0]}</strong>! Seu cadastro foi recebido com sucesso.
            O Guilherme vai entrar em contato em até 24h para agendar sua aula experimental gratuita.
          </p>
          <div style={{
            background: `${C.accent}10`, border: `1px solid ${C.accent}25`, borderRadius: 12,
            padding: 20, marginBottom: 24, textAlign: "left",
          }}>
            <div style={{ fontSize: "0.8rem", color: C.accent, fontWeight: 600, marginBottom: 8 }}>📋 RESUMO</div>
            <div style={{ fontSize: "0.85rem", color: C.fog, lineHeight: 2 }}>
              <div><strong>Objetivo:</strong> {form.objective || "A definir"}</div>
              <div><strong>Plano de interesse:</strong> {form.plan || "A definir"}</div>
              <div><strong>Contato:</strong> {form.phone}</div>
            </div>
          </div>
          <Btn onClick={() => setPage(PAGES.HOME)}>Voltar ao site →</Btn>
        </Card>
      </div>
    );
  }

  return (
    <div style={{ animation: "slideIn 0.5s ease", maxWidth: 680, margin: "0 auto", padding: "48px 24px" }}>
      <SectionTag>CADASTRE-SE</SectionTag>
      <SectionTitle>COMECE SUA TRANSFORMAÇÃO</SectionTitle>
      <p style={{ color: C.smoke, fontSize: "0.95rem", marginTop: 12, marginBottom: 40, lineHeight: 1.7 }}>
        Preencha seus dados e o Guilherme entrará em contato para agendar sua aula experimental gratuita.
      </p>

      {/* Steps */}
      <div style={{ display: "flex", gap: 8, marginBottom: 32 }}>
        {[1, 2, 3].map(s => (
          <div key={s} style={{
            flex: 1, height: 4, borderRadius: 2,
            background: s <= step ? C.accent : C.steel,
            transition: "all 0.3s ease",
          }} />
        ))}
      </div>

      {step === 1 && (
        <Card style={{ animation: "slideIn 0.3s ease" }}>
          <h3 style={{ fontFamily: S.fontDisplay, fontSize: "1.4rem", marginBottom: 24 }}>👤 DADOS PESSOAIS</h3>
          <Input label="Nome completo" value={form.name} onChange={v => update("name", v)} placeholder="Seu nome completo" required />
          <Input label="E-mail" type="email" value={form.email} onChange={v => update("email", v)} placeholder="seu@email.com" required />
          <Input label="WhatsApp" type="tel" value={form.phone} onChange={v => update("phone", v)} placeholder="(48) 99999-9999" required />
          <Input label="Data de nascimento" type="date" value={form.birthDate} onChange={v => update("birthDate", v)} required />
          <div style={{ display: "flex", justifyContent: "flex-end", marginTop: 8 }}>
            <Btn onClick={() => setStep(2)} disabled={!form.name || !form.email || !form.phone}>Próximo →</Btn>
          </div>
        </Card>
      )}

      {step === 2 && (
        <Card style={{ animation: "slideIn 0.3s ease" }}>
          <h3 style={{ fontFamily: S.fontDisplay, fontSize: "1.4rem", marginBottom: 24 }}>🎯 SEU OBJETIVO</h3>
          <Select label="Objetivo principal" value={form.objective} onChange={v => update("objective", v)} required options={[
            { value: "", label: "Selecione seu objetivo..." },
            ...TRAINING_TYPES.map(t => ({ value: t.name, label: `${t.icon} ${t.name}` })),
          ]} />
          <Select label="Plano de interesse" value={form.plan} onChange={v => update("plan", v)} options={[
            { value: "", label: "Ainda não decidi" },
            ...PLANS_DATA.map(p => ({ value: p.name, label: `${p.name} — R$${p.price}/mês (${p.sessions}×/sem)` })),
          ]} />
          <Input label="Condições de saúde relevantes" value={form.healthNotes} onChange={v => update("healthNotes", v)}
            placeholder="Lesões, cirurgias, restrições médicas, medicamentos..." textarea />
          <div style={{ display: "flex", justifyContent: "space-between", marginTop: 8 }}>
            <Btn variant="ghost" onClick={() => setStep(1)}>← Voltar</Btn>
            <Btn onClick={() => setStep(3)} disabled={!form.objective}>Próximo →</Btn>
          </div>
        </Card>
      )}

      {step === 3 && (
        <Card style={{ animation: "slideIn 0.3s ease" }}>
          <h3 style={{ fontFamily: S.fontDisplay, fontSize: "1.4rem", marginBottom: 24 }}>💬 FINALIZAR</h3>
          <Select label="Como conheceu o Guilherme?" value={form.howFound} onChange={v => update("howFound", v)} options={[
            { value: "", label: "Selecione..." }, { value: "instagram", label: "Instagram" },
            { value: "indicacao", label: "Indicação de amigo/aluno" }, { value: "google", label: "Google" },
            { value: "academia", label: "Na academia" }, { value: "outro", label: "Outro" },
          ]} />
          <Input label="Mensagem (opcional)" value={form.message} onChange={v => update("message", v)}
            placeholder="Algo que queira compartilhar, horários preferidos, dúvidas..." textarea />
          
          <div style={{
            background: `${C.accent}08`, border: `1px solid ${C.accent}15`, borderRadius: 12,
            padding: 20, marginBottom: 20, marginTop: 8,
          }}>
            <div style={{ fontSize: "0.8rem", color: C.accent, fontWeight: 600, marginBottom: 10 }}>📋 CONFERIR DADOS</div>
            <div style={{ fontSize: "0.85rem", color: C.fog, lineHeight: 2 }}>
              <div><strong>Nome:</strong> {form.name}</div>
              <div><strong>E-mail:</strong> {form.email}</div>
              <div><strong>WhatsApp:</strong> {form.phone}</div>
              <div><strong>Objetivo:</strong> {form.objective}</div>
              <div><strong>Plano:</strong> {form.plan || "A definir"}</div>
            </div>
          </div>

          <div style={{ display: "flex", justifyContent: "space-between" }}>
            <Btn variant="ghost" onClick={() => setStep(2)}>← Voltar</Btn>
            <Btn onClick={() => setSubmitted(true)}>✓ Enviar cadastro</Btn>
          </div>
        </Card>
      )}
    </div>
  );
}

// ===== PAGE: STUDENT EVOLUTION PORTAL =====
function StudentEvolutionPage({ setPage }) {
  const [showForm, setShowForm] = useState(false);
  const emptyEntry = { date: new Date().toISOString().split("T")[0], source: "manual", notes: "" };
  Object.keys(ALL_MEASUREMENT_FIELDS).forEach(k => { emptyEntry[k] = ""; });
  const [newEntry, setNewEntry] = useState({ ...emptyEntry });
  const [history, setHistory] = useState(MOCK_EVOLUTION_HISTORY);
  const [saved, setSaved] = useState(false);
  const [detailRow, setDetailRow] = useState(null);
  const updateEntry = (k, v) => setNewEntry(p => ({ ...p, [k]: v }));

  const currentDevice = DEVICE_FIELDS[newEntry.source] || DEVICE_FIELDS.manual;
  const visibleFields = currentDevice.fields;

  const groupLabels = {
    basic: { label: "COMPOSIÇÃO CORPORAL", icon: "⚖️", color: C.ocean },
    advanced: { label: "COMPOSIÇÃO AVANÇADA", icon: "🧬", color: C.purple },
    segmental: { label: "ANÁLISE SEGMENTAR", icon: "🦾", color: C.warm },
    measurements: { label: "MEDIDAS CORPORAIS (FITA)", icon: "📐", color: C.accent },
  };

  const getVisibleByGroup = (groupKey) =>
    Object.entries(ALL_MEASUREMENT_FIELDS)
      .filter(([k, f]) => f.group === groupKey && visibleFields.includes(k));

  const handleSave = () => {
    const cleaned = { ...newEntry };
    Object.keys(ALL_MEASUREMENT_FIELDS).forEach(k => {
      if (cleaned[k] === "" || cleaned[k] === undefined) cleaned[k] = null;
      else if (!ALL_MEASUREMENT_FIELDS[k]?.isText) cleaned[k] = parseFloat(cleaned[k]);
    });
    const entry = { ...cleaned, id: Date.now() };
    if (entry.weight && !entry.bmi) entry.bmi = (parseFloat(entry.weight) / (1.78 * 1.78)).toFixed(1);
    setHistory(prev => [entry, ...prev]);
    setSaved(true);
    setTimeout(() => { setSaved(false); setShowForm(false); setNewEntry({ ...emptyEntry }); }, 2000);
  };

  return (
    <div style={{ animation: "slideIn 0.5s ease", maxWidth: 1000, margin: "0 auto", padding: "40px 24px" }}>
      {/* Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 32 }}>
        <div>
          <SectionTag>MINHA EVOLUÇÃO</SectionTag>
          <SectionTitle>HISTÓRICO DE MEDIDAS</SectionTitle>
          <p style={{ color: C.smoke, fontSize: "0.9rem", marginTop: 8 }}>
            Registre suas medidas de qualquer aparelho e acompanhe sua evolução.
          </p>
        </div>
        <Btn onClick={() => setShowForm(!showForm)}>
          {showForm ? "✕ Fechar" : "＋ Nova medição"}
        </Btn>
      </div>

      {/* New Entry Form */}
      {showForm && (
        <Card style={{ marginBottom: 32, animation: "slideIn 0.3s ease", border: `1px solid ${C.accent}20` }}>
          <h3 style={{ fontFamily: S.fontDisplay, fontSize: "1.3rem", marginBottom: 4 }}>📏 NOVA MEDIÇÃO</h3>
          <p style={{ fontSize: "0.8rem", color: C.smoke, marginBottom: 20 }}>
            Selecione o aparelho usado e preencha os campos disponíveis. O formulário se adapta automaticamente.
          </p>

          {/* Date + Source selector */}
          <div style={{ display: "grid", gridTemplateColumns: "1fr 2fr", gap: 16, marginBottom: 20 }}>
            <Input label="Data" type="date" value={newEntry.date} onChange={v => updateEntry("date", v)} required />
            <div>
              <label style={{ display: "block", fontSize: "0.8rem", color: C.fog, marginBottom: 6, fontWeight: 500 }}>
                Aparelho utilizado <span style={{ color: C.coral }}>*</span>
              </label>
              <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
                {Object.entries(DEVICE_FIELDS).map(([key, dev]) => (
                  <button key={key} onClick={() => updateEntry("source", key)} style={{
                    padding: "8px 14px", borderRadius: 10,
                    background: newEntry.source === key ? `${dev.color}18` : "rgba(255,255,255,0.03)",
                    border: newEntry.source === key ? `1.5px solid ${dev.color}50` : "1px solid rgba(255,255,255,0.06)",
                    color: newEntry.source === key ? dev.color : C.smoke,
                    fontSize: "0.78rem", fontWeight: 600, cursor: "pointer",
                    fontFamily: S.fontBody, transition: "all 0.2s ease",
                    display: "flex", alignItems: "center", gap: 6,
                  }}>
                    <span>{dev.icon}</span> {dev.name.split(" ")[0]}
                  </button>
                ))}
              </div>
            </div>
          </div>

          {/* Device info banner */}
          <div style={{
            display: "flex", alignItems: "center", gap: 12, padding: "10px 16px",
            background: `${currentDevice.color}08`, border: `1px solid ${currentDevice.color}15`,
            borderRadius: 10, marginBottom: 20,
          }}>
            <span style={{ fontSize: "1.4rem" }}>{currentDevice.icon}</span>
            <div>
              <div style={{ fontSize: "0.82rem", fontWeight: 600, color: currentDevice.color }}>{currentDevice.name}</div>
              <div style={{ fontSize: "0.72rem", color: C.smoke }}>{currentDevice.inputMethod} — {visibleFields.length} campos disponíveis</div>
            </div>
            {newEntry.source === "relaxmedic" && (
              <div style={{
                marginLeft: "auto", padding: "4px 10px", borderRadius: 6,
                background: `${C.purple}15`, border: `1px solid ${C.purple}25`,
                fontSize: "0.68rem", color: C.purple, fontFamily: S.fontMono,
              }}>App RelaxFIT → PDF → Copiar dados</div>
            )}
            {newEntry.source === "anovator" && (
              <div style={{
                marginLeft: "auto", padding: "4px 10px", borderRadius: 6,
                background: `${C.ocean}15`, border: `1px solid ${C.ocean}25`,
                fontSize: "0.68rem", color: C.ocean, fontFamily: S.fontMono,
              }}>Cole o link anovator.com/body/…</div>
            )}
          </div>

          {/* Dynamic field groups */}
          {Object.entries(groupLabels).map(([groupKey, group]) => {
            const fields = getVisibleByGroup(groupKey);
            if (fields.length === 0) return null;
            return (
              <div key={groupKey} style={{
                background: `${group.color}06`, border: `1px solid ${group.color}12`,
                borderRadius: 12, padding: "16px 20px", marginBottom: 16,
              }}>
                <div style={{
                  fontSize: "0.75rem", fontWeight: 700, color: group.color,
                  marginBottom: 12, letterSpacing: 1,
                  display: "flex", alignItems: "center", gap: 8,
                }}>
                  {group.icon} {group.label}
                  <span style={{
                    fontSize: "0.65rem", padding: "1px 6px", borderRadius: 4,
                    background: `${group.color}12`, color: `${group.color}CC`,
                    fontFamily: S.fontMono, fontWeight: 500,
                  }}>{fields.length}</span>
                </div>
                <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: "0 16px" }}>
                  {fields.map(([fieldKey, field]) => (
                    <Input
                      key={fieldKey}
                      label={field.label}
                      type={field.isText ? "text" : "number"}
                      value={newEntry[fieldKey]}
                      onChange={v => updateEntry(fieldKey, v)}
                      unit={field.unit}
                      placeholder={field.isText ? "—" : "0.0"}
                    />
                  ))}
                </div>
              </div>
            );
          })}

          <Input label="Observações" value={newEntry.notes} onChange={v => updateEntry("notes", v)}
            placeholder="Ex: em jejum, após treino, horário, condições..." textarea />

          <div style={{ display: "flex", justifyContent: "flex-end", gap: 12 }}>
            <Btn variant="ghost" onClick={() => setShowForm(false)}>Cancelar</Btn>
            <Btn onClick={handleSave} disabled={!newEntry.weight}>
              {saved ? "✓ Salvo!" : "💾 Salvar medição"}
            </Btn>
          </div>
        </Card>
      )}

      {/* Evolution Summary Cards */}
      {history.length > 1 && (
        <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16, marginBottom: 24 }}>
          {[
            { label: "Peso atual", key: "weight", unit: "kg", color: C.accent },
            { label: "% Gordura", key: "bodyFat", unit: "%", color: C.ocean },
            { label: "Massa muscular", key: "muscleMass", unit: "kg", color: C.green },
            { label: "Cintura", key: "waist", unit: "cm", color: C.warm },
          ].map((m, i) => {
            const curr = history[0]?.[m.key];
            const first = history[history.length - 1]?.[m.key];
            const diff = curr && first ? (curr - first).toFixed(1) : null;
            return (
              <Card key={i} style={{ padding: 20 }}>
                <div style={{ fontSize: "0.72rem", color: C.smoke, textTransform: "uppercase", letterSpacing: 1, marginBottom: 4 }}>{m.label}</div>
                <div style={{ fontFamily: S.fontDisplay, fontSize: "2rem", color: m.color }}>{curr ?? "—"}<span style={{ fontSize: "0.9rem", color: C.smoke }}>{m.unit}</span></div>
                {diff && (
                  <div style={{ fontSize: "0.75rem", color: parseFloat(diff) < 0 ? C.green : C.coral, marginTop: 2 }}>
                    {parseFloat(diff) > 0 ? "↑" : "↓"} {Math.abs(diff)}{m.unit} desde início
                  </div>
                )}
              </Card>
            );
          })}
        </div>
      )}

      {/* Devices used summary */}
      <div style={{ display: "flex", gap: 8, marginBottom: 20, flexWrap: "wrap" }}>
        <span style={{ fontSize: "0.75rem", color: C.smoke, lineHeight: "28px" }}>Aparelhos utilizados:</span>
        {[...new Set(history.map(h => h.source))].map(src => (
          <SourceBadge key={src} source={src} />
        ))}
      </div>

      {/* History Table */}
      <Card style={{ padding: 0, overflow: "hidden" }}>
        <div style={{
          padding: "16px 24px", borderBottom: "1px solid rgba(255,255,255,0.04)",
          display: "flex", justifyContent: "space-between", alignItems: "center",
        }}>
          <span style={{ fontFamily: S.fontDisplay, fontSize: "1.1rem", letterSpacing: 1 }}>HISTÓRICO COMPLETO</span>
          <span style={{ fontSize: "0.75rem", color: C.smoke }}>{history.length} registros</span>
        </div>
        <div style={{ overflowX: "auto" }}>
          <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "0.82rem" }}>
            <thead>
              <tr style={{ borderBottom: "1px solid rgba(255,255,255,0.06)" }}>
                {["Data", "Fonte", "Peso", "% Gord.", "M. Musc.", "IMC", "Água", "G. Visc.", "M. Óssea", ""].map(h => (
                  <th key={h} style={{ padding: "12px 14px", textAlign: "left", color: C.smoke, fontWeight: 600, fontSize: "0.72rem", letterSpacing: 1, textTransform: "uppercase", whiteSpace: "nowrap" }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {history.map((row, i) => (
                <>
                  <tr key={row.id} onClick={() => setDetailRow(detailRow === row.id ? null : row.id)}
                    style={{
                      borderBottom: "1px solid rgba(255,255,255,0.02)", transition: "background 0.2s",
                      background: i === 0 ? `${C.accent}05` : detailRow === row.id ? `${C.ocean}05` : "transparent",
                      cursor: "pointer",
                    }}>
                    <td style={{ padding: "12px 14px", fontFamily: S.fontMono, fontSize: "0.8rem", color: C.accent, whiteSpace: "nowrap" }}>{row.date}</td>
                    <td style={{ padding: "12px 14px" }}><SourceBadge source={row.source} /></td>
                    <td style={{ padding: "12px 14px", fontFamily: S.fontMono, color: row.weight ? C.white : C.steel }}>{row.weight ?? "—"}</td>
                    <td style={{ padding: "12px 14px", fontFamily: S.fontMono, color: row.bodyFat ? C.white : C.steel }}>{row.bodyFat ?? "—"}</td>
                    <td style={{ padding: "12px 14px", fontFamily: S.fontMono, color: row.muscleMass ? C.white : C.steel }}>{row.muscleMass ?? "—"}</td>
                    <td style={{ padding: "12px 14px", fontFamily: S.fontMono, color: row.bmi ? C.white : C.steel }}>{row.bmi ?? "—"}</td>
                    <td style={{ padding: "12px 14px", fontFamily: S.fontMono, color: row.bodyWater ? C.white : C.steel }}>{row.bodyWater ?? "—"}</td>
                    <td style={{ padding: "12px 14px", fontFamily: S.fontMono, color: row.visceralFat ? C.white : C.steel }}>{row.visceralFat ?? "—"}</td>
                    <td style={{ padding: "12px 14px", fontFamily: S.fontMono, color: row.boneMass ? C.white : C.steel }}>{row.boneMass ?? "—"}</td>
                    <td style={{ padding: "12px 14px", color: C.smoke, fontSize: "0.8rem" }}>{detailRow === row.id ? "▲" : "▼"}</td>
                  </tr>
                  {detailRow === row.id && (
                    <tr key={`${row.id}-detail`}>
                      <td colSpan={10} style={{ padding: "0 14px 16px", background: `${C.graphite}` }}>
                        <div style={{
                          display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 10,
                          padding: 16, background: C.coal, borderRadius: 12,
                          border: "1px solid rgba(255,255,255,0.04)",
                        }}>
                          {Object.entries(ALL_MEASUREMENT_FIELDS).map(([key, field]) => {
                            const val = row[key];
                            if (val === null || val === undefined || val === "") return null;
                            return (
                              <div key={key} style={{ padding: "6px 10px" }}>
                                <div style={{ fontSize: "0.65rem", color: C.smoke, marginBottom: 2 }}>{field.label}</div>
                                <div style={{ fontFamily: S.fontMono, fontSize: "0.85rem", color: C.accent }}>
                                  {val}{field.unit && <span style={{ fontSize: "0.7rem", color: C.smoke, marginLeft: 2 }}>{field.unit}</span>}
                                </div>
                              </div>
                            );
                          })}
                          {row.notes && (
                            <div style={{ gridColumn: "1 / -1", padding: "6px 10px", borderTop: "1px solid rgba(255,255,255,0.04)", marginTop: 4 }}>
                              <div style={{ fontSize: "0.65rem", color: C.smoke, marginBottom: 2 }}>📝 Observações</div>
                              <div style={{ fontSize: "0.82rem", color: C.fog }}>{row.notes}</div>
                            </div>
                          )}
                        </div>
                      </td>
                    </tr>
                  )}
                </>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
}

// ===== PAGE: ADMIN DASHBOARD =====
function AdminDashboard({ setPage }) {
  const stats = [
    { label: "Alunos Ativos", value: MOCK_STUDENTS.filter(s => s.status === "active").length, color: C.accent, change: "+3 este mês" },
    { label: "Leads", value: MOCK_STUDENTS.filter(s => s.status === "lead").length, color: C.ocean, change: "1 novo" },
    { label: "Receita Estimada", value: `R$ ${(MOCK_STUDENTS.filter(s => s.status === "active").length * 680).toLocaleString("pt-BR")}`, color: C.green, change: "+8% vs jan" },
    { label: "Taxa Retenção", value: "94%", color: C.warm, change: "Excelente" },
  ];
  return (
    <div style={{ animation: "slideIn 0.5s ease", maxWidth: 1100, margin: "0 auto", padding: "40px 24px" }}>
      <div style={{ marginBottom: 32 }}>
        <SectionTag>PAINEL ADMIN</SectionTag>
        <SectionTitle>BOM DIA, GUILHERME 💪</SectionTitle>
      </div>

      {/* Stats */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16, marginBottom: 32 }}>
        {stats.map((s, i) => (
          <Card key={i} style={{ padding: 20 }}>
            <div style={{ fontSize: "0.7rem", color: C.smoke, textTransform: "uppercase", letterSpacing: 1.5, marginBottom: 4 }}>{s.label}</div>
            <div style={{ fontFamily: S.fontDisplay, fontSize: "2.2rem", color: s.color, lineHeight: 1 }}>{s.value}</div>
            <div style={{ fontSize: "0.72rem", color: C.accent, marginTop: 4 }}>↑ {s.change}</div>
          </Card>
        ))}
      </div>

      {/* Quick Actions */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 16, marginBottom: 32 }}>
        {[
          { icon: "👥", title: "Gerenciar Alunos", desc: "Ver todos, editar fichas, adicionar", page: PAGES.ADMIN_STUDENTS },
          { icon: "🌐", title: "Editar Site", desc: "Conteúdo da página, valores, textos", page: PAGES.ADMIN_SITE },
          { icon: "📊", title: "Portal do Aluno", desc: "Visualizar como aluno vê", page: PAGES.STUDENT_PORTAL },
        ].map((a, i) => (
          <Card key={i} onClick={() => setPage(a.page)} style={{ cursor: "pointer", padding: 28 }}>
            <div style={{ fontSize: "2rem", marginBottom: 12 }}>{a.icon}</div>
            <div style={{ fontFamily: S.fontDisplay, fontSize: "1.2rem", letterSpacing: 0.5, marginBottom: 4 }}>{a.title.toUpperCase()}</div>
            <div style={{ fontSize: "0.82rem", color: C.smoke }}>{a.desc}</div>
          </Card>
        ))}
      </div>

      {/* Recent Leads */}
      <Card>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
          <span style={{ fontFamily: S.fontDisplay, fontSize: "1.2rem", letterSpacing: 1 }}>LEADS RECENTES</span>
          <Btn variant="ghost" onClick={() => setPage(PAGES.ADMIN_STUDENTS)} style={{ fontSize: "0.75rem", padding: "6px 14px" }}>Ver todos →</Btn>
        </div>
        {MOCK_STUDENTS.filter(s => s.status === "lead").map(s => (
          <div key={s.id} style={{
            display: "flex", alignItems: "center", justifyContent: "space-between",
            padding: "12px 0", borderBottom: "1px solid rgba(255,255,255,0.03)",
          }}>
            <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
              <div style={{ width: 38, height: 38, borderRadius: 10, background: `${C.ocean}20`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: "0.75rem", fontWeight: 700, color: C.ocean }}>{s.avatar}</div>
              <div>
                <div style={{ fontSize: "0.9rem", fontWeight: 600 }}>{s.name}</div>
                <div style={{ fontSize: "0.75rem", color: C.smoke }}>{s.objective} · {s.email}</div>
              </div>
            </div>
            <Btn variant="outline" style={{ fontSize: "0.72rem", padding: "6px 14px" }}>Contatar →</Btn>
          </div>
        ))}
      </Card>
    </div>
  );
}

// ===== PAGE: ADMIN - STUDENTS =====
function AdminStudentsPage({ setPage, setSelectedStudentId }) {
  const [filter, setFilter] = useState("all");
  const [search, setSearch] = useState("");
  const filtered = MOCK_STUDENTS.filter(s => {
    if (filter !== "all" && s.status !== filter) return false;
    if (search && !s.name.toLowerCase().includes(search.toLowerCase())) return false;
    return true;
  });

  return (
    <div style={{ animation: "slideIn 0.5s ease", maxWidth: 1100, margin: "0 auto", padding: "40px 24px" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 32 }}>
        <div>
          <SectionTag>GESTÃO</SectionTag>
          <SectionTitle>ALUNOS</SectionTitle>
        </div>
        <Btn>＋ Novo aluno</Btn>
      </div>

      {/* Filters */}
      <div style={{ display: "flex", gap: 12, marginBottom: 24, alignItems: "center" }}>
        <input type="text" value={search} onChange={e => setSearch(e.target.value)}
          placeholder="🔍  Buscar aluno..." style={{
            padding: "10px 16px", background: "rgba(255,255,255,0.04)",
            border: "1px solid rgba(255,255,255,0.08)", borderRadius: 10,
            color: C.white, fontFamily: S.fontBody, fontSize: "0.85rem", width: 280,
          }} />
        {[
          { val: "all", label: `Todos (${MOCK_STUDENTS.length})` },
          { val: "active", label: `Ativos (${MOCK_STUDENTS.filter(s => s.status === "active").length})` },
          { val: "paused", label: `Pausados` },
          { val: "lead", label: `Leads` },
        ].map(f => (
          <button key={f.val} onClick={() => setFilter(f.val)} style={{
            padding: "8px 16px", borderRadius: 8,
            background: filter === f.val ? `${C.accent}12` : "transparent",
            border: filter === f.val ? `1px solid ${C.accent}25` : "1px solid rgba(255,255,255,0.06)",
            color: filter === f.val ? C.accent : C.smoke,
            fontSize: "0.8rem", fontWeight: 600, cursor: "pointer",
            fontFamily: S.fontBody,
          }}>{f.label}</button>
        ))}
      </div>

      {/* Students List */}
      <Card style={{ padding: 0, overflow: "hidden" }}>
        {filtered.map((s, i) => (
          <div key={s.id} onClick={() => { setSelectedStudentId(s.id); setPage(PAGES.ADMIN_STUDENT_DETAIL); }}
            style={{
              display: "grid", gridTemplateColumns: "2fr 1fr 1fr 1fr auto",
              alignItems: "center", padding: "16px 24px", cursor: "pointer",
              borderBottom: i < filtered.length - 1 ? "1px solid rgba(255,255,255,0.03)" : "none",
              transition: "background 0.2s",
            }}
            onMouseEnter={e => e.currentTarget.style.background = `${C.accent}05`}
            onMouseLeave={e => e.currentTarget.style.background = "transparent"}>
            <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
              <div style={{
                width: 42, height: 42, borderRadius: 12,
                background: s.status === "active" ? `linear-gradient(135deg, ${C.accent}, ${C.ocean})` : C.steel,
                display: "flex", alignItems: "center", justifyContent: "center",
                fontSize: "0.8rem", fontWeight: 700, color: s.status === "active" ? C.coal : C.smoke,
              }}>{s.avatar}</div>
              <div>
                <div style={{ fontSize: "0.9rem", fontWeight: 600 }}>{s.name}</div>
                <div style={{ fontSize: "0.75rem", color: C.smoke }}>{s.objective} · {s.plan}</div>
              </div>
            </div>
            <StatusBadge status={s.status} />
            <div style={{ fontSize: "0.8rem", color: C.fog }}>{s.sessions} sessões</div>
            <div style={{ fontSize: "0.78rem", color: C.smoke, fontFamily: S.fontMono }}>{s.lastSession || "—"}</div>
            <span style={{ color: C.smoke, fontSize: "0.9rem" }}>→</span>
          </div>
        ))}
      </Card>
    </div>
  );
}

// ===== PAGE: ADMIN - STUDENT DETAIL =====
function AdminStudentDetail({ studentId, setPage }) {
  const student = MOCK_STUDENTS.find(s => s.id === studentId) || MOCK_STUDENTS[0];
  return (
    <div style={{ animation: "slideIn 0.5s ease", maxWidth: 1100, margin: "0 auto", padding: "40px 24px" }}>
      <button onClick={() => setPage(PAGES.ADMIN_STUDENTS)} style={{
        background: "none", border: "none", color: C.smoke, cursor: "pointer",
        fontSize: "0.85rem", fontFamily: S.fontBody, marginBottom: 24,
      }}>← Voltar para alunos</button>

      <div style={{ display: "flex", gap: 24, marginBottom: 32 }}>
        <div style={{
          width: 80, height: 80, borderRadius: 20,
          background: `linear-gradient(135deg, ${C.accent}, ${C.ocean})`,
          display: "flex", alignItems: "center", justifyContent: "center",
          fontFamily: S.fontDisplay, fontSize: "1.6rem", color: C.coal,
        }}>{student.avatar}</div>
        <div style={{ flex: 1 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 4 }}>
            <h2 style={{ fontFamily: S.fontDisplay, fontSize: "2rem", margin: 0 }}>{student.name.toUpperCase()}</h2>
            <StatusBadge status={student.status} />
          </div>
          <div style={{ fontSize: "0.9rem", color: C.smoke }}>
            {student.objective} · Plano {student.plan} · {student.sessions} sessões · Desde {student.startDate}
          </div>
          <div style={{ fontSize: "0.82rem", color: C.smoke, marginTop: 4 }}>
            📧 {student.email} · 📱 {student.phone}
          </div>
        </div>
        <Btn variant="outline">✏️ Editar</Btn>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 24 }}>
        {/* Evolution History */}
        <Card>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
            <span style={{ fontFamily: S.fontDisplay, fontSize: "1.1rem" }}>📈 EVOLUÇÃO</span>
            <Btn variant="ghost" style={{ fontSize: "0.72rem", padding: "6px 12px" }}>＋ Nova avaliação</Btn>
          </div>
          {MOCK_EVOLUTION_HISTORY.slice(0, 4).map((e, i) => (
            <div key={e.id} style={{
              display: "flex", justifyContent: "space-between", alignItems: "center",
              padding: "10px 0", borderBottom: i < 3 ? "1px solid rgba(255,255,255,0.03)" : "none",
            }}>
              <div>
                <div style={{ fontSize: "0.82rem", fontFamily: S.fontMono, color: C.accent }}>{e.date}</div>
                <div style={{ fontSize: "0.75rem", color: C.smoke }}>{e.weight}kg · {e.bodyFat ?? "—"}% gord.</div>
              </div>
              <SourceBadge source={e.source} />
            </div>
          ))}
        </Card>

        {/* Quick Actions */}
        <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
          <Card style={{ padding: 20 }}>
            <div style={{ fontFamily: S.fontDisplay, fontSize: "1.1rem", marginBottom: 12 }}>🏋️ TREINO ATUAL</div>
            <div style={{ fontSize: "0.85rem", color: C.fog, marginBottom: 4 }}>Treino A — Peito + Tríceps (Semana 8)</div>
            <div style={{ fontSize: "0.85rem", color: C.fog, marginBottom: 4 }}>Treino B — Costas + Bíceps (Semana 8)</div>
            <div style={{ fontSize: "0.85rem", color: C.fog }}>Treino C — Pernas + Ombros (Semana 8)</div>
            <Btn variant="ghost" full style={{ marginTop: 12, fontSize: "0.78rem" }}>Editar treino →</Btn>
          </Card>

          <Card style={{ padding: 20 }}>
            <div style={{ fontFamily: S.fontDisplay, fontSize: "1.1rem", marginBottom: 12 }}>💰 FINANCEIRO</div>
            <div style={{ display: "flex", justifyContent: "space-between", fontSize: "0.85rem", marginBottom: 6 }}>
              <span style={{ color: C.fog }}>Plano {student.plan}</span>
              <span style={{ color: C.accent, fontFamily: S.fontMono }}>R$ {PLANS_DATA.find(p => p.name === student.plan)?.price || "—"}/mês</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", fontSize: "0.85rem" }}>
              <span style={{ color: C.fog }}>Status pagamento</span>
              <span style={{ color: C.green }}>Em dia ✓</span>
            </div>
          </Card>

          <Card style={{ padding: 20 }}>
            <div style={{ fontFamily: S.fontDisplay, fontSize: "1.1rem", marginBottom: 12 }}>⚙️ AÇÕES</div>
            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              <Btn variant="ghost" full style={{ justifyContent: "flex-start", fontSize: "0.82rem" }}>📊 Importar Anovator</Btn>
              <Btn variant="ghost" full style={{ justifyContent: "flex-start", fontSize: "0.82rem" }}>📸 Fotos comparativas</Btn>
              <Btn variant="ghost" full style={{ justifyContent: "flex-start", fontSize: "0.82rem" }}>💬 Enviar mensagem</Btn>
              <Btn variant="danger" full style={{ justifyContent: "flex-start", fontSize: "0.82rem" }}>⏸ Pausar aluno</Btn>
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}

// ===== PAGE: ADMIN - SITE EDITOR =====
function AdminSitePage({ setPage }) {
  const [hero, setHero] = useState({ title1: "TRANSFORME SEU", title2: "CORPO", title3: " E SUA", title4: "MENTALIDADE", subtitle: "Treinamento personalizado para todas as idades e objetivos." });
  const [saved, setSaved] = useState(false);
  const handleSave = () => { setSaved(true); setTimeout(() => setSaved(false), 2500); };

  return (
    <div style={{ animation: "slideIn 0.5s ease", maxWidth: 1100, margin: "0 auto", padding: "40px 24px" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 32 }}>
        <div>
          <SectionTag>ADMIN</SectionTag>
          <SectionTitle>EDITAR SITE</SectionTitle>
          <p style={{ color: C.smoke, fontSize: "0.9rem", marginTop: 8 }}>Gerencie o conteúdo da sua página principal, valores e textos.</p>
        </div>
        <Btn onClick={handleSave}>{saved ? "✓ Salvo!" : "💾 Salvar alterações"}</Btn>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 24 }}>
        {/* Hero Section */}
        <Card>
          <h3 style={{ fontFamily: S.fontDisplay, fontSize: "1.2rem", marginBottom: 20 }}>🏠 HERO (TOPO DO SITE)</h3>
          <Input label="Título linha 1" value={hero.title1} onChange={v => setHero(p => ({ ...p, title1: v }))} />
          <Input label="Título linha 2 (destaque)" value={hero.title2} onChange={v => setHero(p => ({ ...p, title2: v }))} />
          <Input label="Título linha 3" value={hero.title3} onChange={v => setHero(p => ({ ...p, title3: v }))} />
          <Input label="Título linha 4" value={hero.title4} onChange={v => setHero(p => ({ ...p, title4: v }))} />
          <Input label="Subtítulo" value={hero.subtitle} onChange={v => setHero(p => ({ ...p, subtitle: v }))} textarea />
          <div style={{ marginTop: 16, padding: 16, background: C.coal, borderRadius: 12, border: "1px solid rgba(255,255,255,0.04)" }}>
            <div style={{ fontSize: "0.68rem", color: C.smoke, marginBottom: 8, letterSpacing: 1 }}>PREVIEW</div>
            <div style={{ fontFamily: S.fontDisplay, fontSize: "1.8rem", lineHeight: 0.95 }}>
              {hero.title1}<br /><span style={{ color: C.accent }}>{hero.title2}</span>{hero.title3}<br />{hero.title4}
            </div>
            <div style={{ fontSize: "0.78rem", color: C.smoke, marginTop: 8 }}>{hero.subtitle}</div>
          </div>
        </Card>

        {/* Plans Management */}
        <Card>
          <h3 style={{ fontFamily: S.fontDisplay, fontSize: "1.2rem", marginBottom: 20 }}>💰 PLANOS & VALORES</h3>
          {PLANS_DATA.map(plan => (
            <div key={plan.id} style={{
              display: "flex", justifyContent: "space-between", alignItems: "center",
              padding: "14px 16px", background: C.coal, borderRadius: 12,
              border: "1px solid rgba(255,255,255,0.04)", marginBottom: 10,
            }}>
              <div>
                <div style={{ fontWeight: 600, fontSize: "0.9rem" }}>{plan.name}</div>
                <div style={{ fontSize: "0.75rem", color: C.smoke }}>{plan.sessions}×/sem · {plan.features.length} benefícios</div>
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                <span style={{ fontFamily: S.fontDisplay, fontSize: "1.4rem", color: C.accent }}>R${plan.price}</span>
                <button style={{
                  background: "none", border: "1px solid rgba(255,255,255,0.1)",
                  borderRadius: 6, padding: "4px 10px", color: C.smoke,
                  fontSize: "0.72rem", cursor: "pointer",
                }}>Editar</button>
              </div>
            </div>
          ))}
          <Btn variant="ghost" full style={{ marginTop: 8 }}>＋ Adicionar plano</Btn>
        </Card>

        {/* Training Types */}
        <Card>
          <h3 style={{ fontFamily: S.fontDisplay, fontSize: "1.2rem", marginBottom: 20 }}>🏋️ TIPOS DE TREINO</h3>
          {TRAINING_TYPES.map((t, i) => (
            <div key={i} style={{
              display: "flex", justifyContent: "space-between", alignItems: "center",
              padding: "10px 0", borderBottom: i < TRAINING_TYPES.length - 1 ? "1px solid rgba(255,255,255,0.03)" : "none",
            }}>
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <span>{t.icon}</span>
                <span style={{ fontSize: "0.85rem", fontWeight: 600 }}>{t.name}</span>
              </div>
              <button style={{
                background: "none", border: "1px solid rgba(255,255,255,0.1)",
                borderRadius: 6, padding: "4px 10px", color: C.smoke,
                fontSize: "0.72rem", cursor: "pointer",
              }}>Editar</button>
            </div>
          ))}
        </Card>

        {/* SEO & Contato */}
        <Card>
          <h3 style={{ fontFamily: S.fontDisplay, fontSize: "1.2rem", marginBottom: 20 }}>📱 CONTATO & SEO</h3>
          <Input label="WhatsApp" value="(48) 99999-9999" onChange={() => {}} placeholder="(48) 99999-9999" icon="📱" />
          <Input label="Instagram" value="@guilhermealmeida.pt" onChange={() => {}} placeholder="@usuario" icon="📸" />
          <Input label="Endereço" value="Jurerê, Florianópolis - SC" onChange={() => {}} icon="📍" />
          <Input label="Horário de atendimento" value="Seg-Sex: 06h-21h | Sáb: 07h-12h" onChange={() => {}} icon="🕐" />
          <Input label="Meta description (SEO)" value="Personal Trainer em Jurerê, Florianópolis. Emagrecimento, hipertrofia e hybrid training." onChange={() => {}} textarea icon="🔍" />
        </Card>
      </div>
    </div>
  );
}

// ===== PAGE: STUDENT PORTAL (HUB) =====
function StudentPortalPage({ setPage }) {
  return (
    <div style={{ animation: "slideIn 0.5s ease", maxWidth: 900, margin: "0 auto", padding: "40px 24px" }}>
      <div style={{ marginBottom: 32 }}>
        <SectionTag>PORTAL DO ALUNO</SectionTag>
        <SectionTitle>OLÁ, ANA CAROLINA 👋</SectionTitle>
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>
        {[
          { icon: "📋", title: "Meu Treino", desc: "Visualize sua planilha de treino atual", color: C.accent },
          { icon: "📏", title: "Minha Evolução", desc: "Registre medidas e acompanhe resultados", color: C.ocean, page: PAGES.STUDENT_EVOLUTION },
          { icon: "📅", title: "Minha Agenda", desc: "Veja e confirme seus horários", color: C.warm },
          { icon: "💬", title: "Falar com Guilherme", desc: "Mensagem direta com o personal", color: C.green },
          { icon: "📊", title: "Bioimpedância", desc: "Importe do Anovator, Relaxmedic ou outro aparelho", color: C.purple },
          { icon: "🎯", title: "Minhas Metas", desc: "Acompanhe seu progresso nas metas", color: C.coral },
        ].map((item, i) => (
          <Card key={i} onClick={() => item.page && setPage(item.page)}
            style={{ cursor: item.page ? "pointer" : "default", padding: 28, borderLeft: `3px solid ${item.color}` }}>
            <div style={{ fontSize: "2rem", marginBottom: 12 }}>{item.icon}</div>
            <div style={{ fontFamily: S.fontDisplay, fontSize: "1.2rem", letterSpacing: 0.5, marginBottom: 4 }}>{item.title.toUpperCase()}</div>
            <div style={{ fontSize: "0.85rem", color: C.smoke }}>{item.desc}</div>
          </Card>
        ))}
      </div>
    </div>
  );
}

// ===== MAIN APP =====
export default function GAPersonalApp() {
  const [page, setPage] = useState(PAGES.HOME);
  const [selectedStudentId, setSelectedStudentId] = useState(null);
  const isAdmin = [PAGES.ADMIN, PAGES.ADMIN_SITE, PAGES.ADMIN_STUDENTS, PAGES.ADMIN_STUDENT_DETAIL].includes(page);

  useEffect(() => { window.scrollTo({ top: 0, behavior: "smooth" }); }, [page]);

  return (
    <div style={{ minHeight: "100vh", background: C.coal, color: C.white, fontFamily: S.fontBody }}>
      <style>{`
        ${fontCSS}
        * { box-sizing: border-box; margin: 0; padding: 0; }
        ::-webkit-scrollbar { width: 5px; }
        ::-webkit-scrollbar-track { background: ${C.coal}; }
        ::-webkit-scrollbar-thumb { background: ${C.accent}; border-radius: 3px; }
        input:focus, textarea:focus, select:focus { outline: none; border-color: ${C.accent}44 !important; }
        @keyframes slideIn { from { opacity: 0; transform: translateY(16px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes checkmark { 0% { transform: scale(0); } 50% { transform: scale(1.2); } 100% { transform: scale(1); } }
        @keyframes spin { to { transform: rotate(360deg); } }
        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
        @media (max-width: 768px) {
          [style*="grid-template-columns: repeat(3"] { grid-template-columns: 1fr !important; }
          [style*="grid-template-columns: repeat(4"] { grid-template-columns: 1fr 1fr !important; }
          [style*="grid-template-columns: 1fr 1fr"] { grid-template-columns: 1fr !important; }
          [style*="grid-template-columns: 2fr 1fr 1fr 1fr auto"] { grid-template-columns: 1fr !important; }
        }
      `}</style>

      <Navbar currentPage={page} setPage={setPage} isAdmin={isAdmin} />

      {page === PAGES.HOME && (
        <div style={{ animation: "slideIn 0.5s ease", textAlign: "center", padding: "120px 24px 80px" }}>
          <div style={{ maxWidth: 700, margin: "0 auto" }}>
            <div style={{
              display: "inline-flex", alignItems: "center", gap: 8,
              padding: "6px 16px", background: `${C.accent}10`, border: `1px solid ${C.accent}20`,
              borderRadius: 100, fontSize: "0.78rem", color: C.accent, fontWeight: 500,
              letterSpacing: 1.5, textTransform: "uppercase", marginBottom: 32,
            }}>
              <span style={{ width: 6, height: 6, background: C.accent, borderRadius: "50%", animation: "fadeIn 2s ease infinite alternate" }}></span>
              Personal Trainer — Jurerê, Florianópolis
            </div>
            <h1 style={{ fontFamily: S.fontDisplay, fontSize: "clamp(3rem, 8vw, 5.5rem)", lineHeight: 0.95, marginBottom: 24 }}>
              TRANSFORME SEU<br /><span style={{ color: C.accent }}>CORPO</span> E SUA<br />MENTALIDADE
            </h1>
            <p style={{ color: C.smoke, fontSize: "1.1rem", fontWeight: 300, lineHeight: 1.8, maxWidth: 520, margin: "0 auto 40px" }}>
              Treinamento personalizado para todas as idades e objetivos. Emagrecimento, hipertrofia ou hybrid training.
            </p>
            <div style={{ display: "flex", gap: 12, justifyContent: "center", flexWrap: "wrap" }}>
              <Btn onClick={() => setPage(PAGES.REGISTER)}>Comece agora →</Btn>
              <Btn variant="outline" onClick={() => setPage(PAGES.PLANS)}>Ver planos e valores</Btn>
            </div>
            <div style={{ display: "flex", gap: 64, justifyContent: "center", marginTop: 80 }}>
              {[
                { n: "20+", l: "Anos de experiência" },
                { n: "500+", l: "Alunos transformados" },
                { n: "100%", l: "Dedicação" },
              ].map((s, i) => (
                <div key={i} style={{ position: "relative" }}>
                  <div style={{ position: "absolute", top: 0, left: 0, width: 30, height: 3, background: C.accent }} />
                  <div style={{ fontFamily: S.fontDisplay, fontSize: "2.5rem", paddingTop: 12 }}>{s.n}</div>
                  <div style={{ fontSize: "0.75rem", color: C.smoke, textTransform: "uppercase", letterSpacing: 1.5 }}>{s.l}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {page === PAGES.PLANS && <PlansPage setPage={setPage} />}
      {page === PAGES.REGISTER && <RegisterPage setPage={setPage} />}
      {page === PAGES.STUDENT_PORTAL && <StudentPortalPage setPage={setPage} />}
      {page === PAGES.STUDENT_EVOLUTION && <StudentEvolutionPage setPage={setPage} />}
      {page === PAGES.ADMIN && <AdminDashboard setPage={setPage} />}
      {page === PAGES.ADMIN_STUDENTS && <AdminStudentsPage setPage={setPage} setSelectedStudentId={setSelectedStudentId} />}
      {page === PAGES.ADMIN_STUDENT_DETAIL && <AdminStudentDetail studentId={selectedStudentId} setPage={setPage} />}
      {page === PAGES.ADMIN_SITE && <AdminSitePage setPage={setPage} />}

      {/* Footer */}
      <footer style={{
        borderTop: "1px solid rgba(255,255,255,0.03)", padding: "24px",
        display: "flex", justifyContent: "center", alignItems: "center", gap: 16,
        marginTop: 64,
      }}>
        <span style={{ fontSize: "0.72rem", color: C.smoke }}>© 2026 GA Personal — Guilherme Almeida</span>
        <div style={{ display: "flex", gap: 6, alignItems: "center", fontFamily: S.fontMono, fontSize: "0.65rem" }}>
          {["Elixir", "Phoenix", "Vue", "PostgreSQL"].map(t => (
            <span key={t} style={{ padding: "2px 6px", background: `${C.accent}10`, borderRadius: 3, color: C.accent }}>{t}</span>
          ))}
        </div>
      </footer>
    </div>
  );
}
