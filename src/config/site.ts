// site.ts — Remote Work Hub per-site config (Phase 1.2 shared library)
export interface SiteConfig {
  name: string;
  tagline: string;
  url: string;
  logo?: { src: string; alt: string };
  nav: { href: string; label: string }[];
  footerColumns: { heading: string; links: { href: string; label: string }[] }[];
  social: { label: string; href: string }[];
  newsletter: { magnetName: string; valueProp: string; downloadUrl: string };
  legalNote: string;
}

export const site: SiteConfig = {
  name: 'Remote Work Hub',
  tagline: 'Your guide to working from anywhere.',
  url: 'https://remoteworkhub.net',
  nav: [
    { href: '/', label: 'Home' },
    { href: '/all-articles', label: 'Articles' },
    { href: '/about', label: 'About' },
  ],
  footerColumns: [
    {
      heading: 'Quick Links',
      links: [
        { href: '/all-articles', label: 'All Articles' },
        { href: '/about', label: 'About' },
      ],
    },
    {
      heading: 'Resources',
      links: [
        { href: '/checklist', label: 'Checklist' },
        { href: '/store', label: 'Store' },
      ],
    },
    {
      heading: 'Legal',
      links: [
        { href: '/privacy', label: 'Privacy' },
        { href: '/disclaimer', label: 'Disclaimer' },
      ],
    },
  ],
  social: [
    { label: 'X', href: 'https://x.com/RemoteWorkHub' },
    { label: 'LinkedIn', href: 'https://www.linkedin.com/company/remoteworkhub' },
  ],
  newsletter: {
    magnetName: 'Remote Work Starter Kit',
    valueProp: 'Get the free Remote Work Starter Kit — tools, templates, and tips to land remote work.',
    downloadUrl: '/downloads/remote-work-starter-kit.html',
  },
  legalNote: 'Not affiliated with any employer or job board.',
};
