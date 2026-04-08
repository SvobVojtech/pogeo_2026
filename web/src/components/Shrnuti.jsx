import { useReveal } from '../hooks/useReveal'
import StatStrip from './StatStrip'

const FINDINGS = [
  { title: 'Sociodemografie sama nestačí', text: 'Kombinace vzdělání, věku, ekonomiky a religiozity vysvětluje globálně jen ~19 % variability (OLS R² = 0,188). GWR zvyšuje vysvětlitelnost na 44,5 % — ale klíčové je odkrytí lokálních vzorců.' },
  { title: 'Silná prostorová struktura', text: 'Výrazná lokální variabilita koeficientů — vztahy nejsou všude stejné (Moran\'s I OLS = 0,080 ***). Po GWR je prostorová autokorelace eliminována (Moran\'s I GWR = −0,002, p = 0,574 ns).' },
  { title: 'Piráti jako metropolitní fenomén', text: 'Model potvrzuje silný pozitivní efekt vysokoškolského vzdělání v Praze a Brně. V průmyslových regionech se ale koeficient vzdělání obrací — lokální kontext dominuje nad globálním vzorcem.' },
  { title: 'GWR jako efektivní nástroj', text: 'AICc poklesl o 529 bodů (29 130 → 28 601). Adj. R² vzrostl o 11,2 p.p. navzdory penalizaci za 1 272,8 efektivních parametrů. GWR prokázalo přínos nad rámec prostého přetrénování.' },
]

const LIMITS = [
  { title: 'Ekologický klam', text: 'Data jsou agregovaná za obce, nikoli za jednotlivé voliče. Vztahy platí na úrovni obcí — přímá interpretace o individuálním volebním chování by byla metodicky chybná.' },
  { title: 'Malý bandwidth', text: 'BW = 23 sousedů (0,37 % dat) je velmi lokální. Riziko přetrénování existuje, ale je mitigováno adjusted R² — po penalizaci komplexity model stále přináší přírůstek.' },
  { title: 'Chybějící prediktory', text: '6 prediktorů ze SLDB 2021 nepokrývá veškeré determinanty volebního chování. Stranická identita, lokální politický kontext ani historické vzorce nejsou v modelu zahrnuty.' },
]

const FINAL_STATS = [
  { value: 0.188, decimals: 3, label: 'OLS R²', color: 'rgba(255,255,255,0.4)' },
  { value: 0.445, decimals: 3, label: 'GWR R²' },
  { value: 25.6,  decimals: 1, suffix: ' p.p.', label: 'Zlepšení R²' },
  { value: 529,   label: 'Snížení AICc' },
]

export default function Shrnuti() {
  const ref = useReveal()

  return (
    <section id="shrnuti" ref={ref}>
      <div className="container">
        <div className="section-label">10 — Shrnutí</div>
        <h2 className="section-title reveal">
          Klíčová <span className="gold">zjištění</span>
        </h2>
        <p className="section-lead reveal delay-1">
          GWR odkryla prostorovou nestacionaritu, která v globálním OLS modelu
          zůstala skryta.
        </p>

        <div className="two-col-auto reveal delay-2" style={{ marginBottom: '1.5rem' }}>
          {FINDINGS.map(({ title, text }) => (
            <div key={title} className="card">
              <div className="card-label">{title}</div>
              <p style={{ fontSize: '0.9rem', color: 'var(--dim)', margin: 0, lineHeight: 1.6 }}>{text}</p>
            </div>
          ))}
        </div>

        <h3 className="reveal grotesk" style={{ fontSize: '1.05rem', margin: '3rem 0 1rem', color: 'var(--gold)' }}>
          Metodické limity
        </h3>

        <div className="three-col reveal delay-2" style={{ marginBottom: '3rem' }}>
          {LIMITS.map(({ title, text }) => (
            <div key={title} className="card">
              <div className="card-label">{title}</div>
              <p style={{ fontSize: '0.85rem', color: 'var(--dim)', margin: 0, lineHeight: 1.6 }}>{text}</p>
            </div>
          ))}
        </div>

        <div className="big-quote reveal delay-3">
          Volby nejsou univerzální fenomén —<br />
          jejich dynamika se podél mapy mění.
        </div>

        <div className="reveal delay-3">
          <StatStrip items={FINAL_STATS} />
        </div>

        <div style={{ textAlign: 'center', marginTop: '3.5rem' }} className="reveal delay-4">
          <a
            href="/assets/Prezentace_Svobods_mikeska.pptx"
            className="btn-primary"
            download
            style={{ display: 'inline-flex' }}
          >
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none" style={{ marginRight: 6 }} aria-hidden="true">
              <path d="M7 1v8M3 6l4 4 4-4M1 12h12" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            Stáhnout prezentaci (PPTX)
          </a>
        </div>
      </div>
    </section>
  )
}
