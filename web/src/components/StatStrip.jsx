import { useCounter } from '../hooks/useCounter'

function StatItem({ value, decimals = 0, suffix = '', prefix = '', label, color, static: isStatic }) {
  const absValue = Math.abs(value)
  const { ref, value: animated } = useCounter(isStatic ? 0 : absValue, decimals)

  const display = isStatic
    ? (decimals > 0 ? absValue.toFixed(decimals) : absValue.toLocaleString('cs-CZ'))
    : (decimals > 0 ? animated.toFixed(decimals) : Math.round(animated).toLocaleString('cs-CZ'))

  const sign = value < 0 ? '−' : ''

  return (
    <div className="stat-item">
      <span
        className="stat-num"
        ref={ref}
        style={color ? { color } : undefined}
      >
        {prefix}{sign}{display}{suffix}
      </span>
      <span className="stat-label">{label}</span>
    </div>
  )
}

export default function StatStrip({ items }) {
  return (
    <div className="stat-strip">
      {items.map((item, i) => (
        <StatItem key={i} {...item} />
      ))}
    </div>
  )
}
