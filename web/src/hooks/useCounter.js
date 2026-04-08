import { useEffect, useRef, useState } from 'react'

/**
 * Animates a number from 0 to `target` when the element enters the viewport.
 * @param {number} target - Final value
 * @param {number} decimals - Decimal places
 * @param {number} duration - Animation duration in ms
 */
export function useCounter(target, decimals = 0, duration = 1400) {
  const [value, setValue] = useState(0)
  const ref = useRef(null)
  const animated = useRef(false)

  useEffect(() => {
    const el = ref.current
    if (!el) return

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting && !animated.current) {
          animated.current = true
          const start = performance.now()

          const tick = (now) => {
            const elapsed = now - start
            const progress = Math.min(elapsed / duration, 1)
            const ease = 1 - Math.pow(1 - progress, 3)
            setValue(parseFloat((target * ease).toFixed(decimals)))
            if (progress < 1) requestAnimationFrame(tick)
            else setValue(target)
          }

          requestAnimationFrame(tick)
          observer.disconnect()
        }
      },
      { threshold: 0.5 }
    )

    observer.observe(el)
    return () => observer.disconnect()
  }, [target, decimals, duration])

  return { ref, value }
}
