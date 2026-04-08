import { useEffect, useState } from 'react'

/**
 * Returns the id of the section currently in the viewport (for nav highlighting).
 * @param {string[]} sectionIds
 */
export function useActiveSection(sectionIds) {
  const [activeId, setActiveId] = useState('')

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) setActiveId(entry.target.id)
        })
      },
      { threshold: 0.25, rootMargin: '-60px 0px 0px 0px' }
    )

    sectionIds.forEach((id) => {
      const el = document.getElementById(id)
      if (el) observer.observe(el)
    })

    return () => observer.disconnect()
  }, [sectionIds])

  return activeId
}
