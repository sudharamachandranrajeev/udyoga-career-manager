// Communities, professional bodies and events where people in UK health
// administration and digital health meet: the UK-wide ones, then the
// regional health innovation bodies' events across the UK's nations and
// major cities. Static: each link was checked by hand (November 2026).
// Meeting people there is the warmest way in, and "Log people I met" keeps
// them, with where they were met.

/// A place to meet people.
class Community {
  const Community(this.name, this.url, this.why, this.kind, {this.region = ''});
  final String name;
  final String url;

  /// One line on why it is worth the time.
  final String why;

  /// community | event | body
  final String kind;

  /// The region it serves; '' for UK-wide.
  final String region;
}

const communityKinds = {'community': 'Community', 'event': 'Events', 'body': 'Professional body'};

const communities = [
  Community(
    'FutureNHS',
    'https://future.nhs.uk/',
    'The NHS\'s own collaboration platform: workspaces for informatics, digital and admin teams.',
    'community',
  ),
  Community(
    'NHS Networks',
    'https://www.networks.nhs.uk/',
    'Networks of NHS staff by interest, many open to join.',
    'community',
  ),
  Community(
    'Digital Health Networks',
    'https://www.digitalhealth.net/signup-to-the-networks',
    'The CIO, CCIO and CNIO networks for digital health leaders, with regular events.',
    'community',
  ),
  Community(
    'Shuri Network',
    'https://shurinetwork.com/',
    'Women from minority ethnic backgrounds in NHS digital health, with mentoring.',
    'community',
  ),
  Community(
    'AMSPAR',
    'https://www.amspar.com/',
    'The professional body for medical secretaries, practice managers and health administrators.',
    'body',
  ),
  Community(
    'IHRIM',
    'https://ihrim.co.uk/',
    'The Institute of Health Records and Information Management: records and information governance.',
    'body',
  ),
  Community(
    'FEDIP',
    'https://www.fedip.org/',
    'The Federation for Informatics Professionals: a register for health and care informatics staff.',
    'body',
  ),
  Community(
    'BCS Faculty of Health and Care',
    'https://www.bcs.org/membership-and-registrations/member-communities/faculty-of-health-and-care/',
    'BCS\'s health and care informatics community, with events and specialist groups.',
    'body',
  ),
  Community(
    'HL7 UK',
    'https://www.hl7.org.uk/',
    'The UK home of health data standards (FHIR), with a yearly conference.',
    'body',
  ),
  Community(
    'HDR UK',
    'https://www.hdruk.ac.uk/',
    'Health Data Research UK: health data science, training and events.',
    'body',
  ),
  Community(
    'NHS Digital Academy',
    'https://digital-transformation.hee.nhs.uk/about-the-nhs-digital-academy',
    'Development programmes for the NHS digital workforce, and their alumni.',
    'body',
  ),
  // Regional: the health innovation bodies that bring the NHS, industry and
  // universities together, by nation and region, with their events.
  Community(
    'Health Innovation Network (south London)',
    'https://healthinnovationnetwork.com/events/',
    'Events and webinars for NHS, care and industry people across south London.',
    'event',
    region: 'London',
  ),
  Community(
    'Health Innovation Manchester',
    'https://healthinnovationmanchester.com/events/',
    'Greater Manchester\'s health, civic and academic partnership: events on digital and data.',
    'event',
    region: 'Greater Manchester',
  ),
  Community(
    'Health Innovation West Midlands',
    'https://www.healthinnovationwestmidlands.org/',
    'Brings health and care, industry and universities together across Birmingham and the West Midlands.',
    'event',
    region: 'West Midlands',
  ),
  Community(
    'Health Innovation Yorkshire & Humber',
    'https://www.healthinnovationyh.org.uk/events/',
    'Events bringing NHS, industry and universities together across Yorkshire and the Humber.',
    'event',
    region: 'Yorkshire and the Humber',
  ),
  Community(
    'Health Innovation North East and North Cumbria',
    'https://healthinnovationnenc.org.uk/event/',
    'Events for the NHS trusts, universities and companies of the North East and North Cumbria.',
    'event',
    region: 'North East',
  ),
  Community(
    'Digital Health & Care Innovation Centre',
    'https://www.dhi-scotland.com/event-list',
    'Scotland\'s digital health and care innovation centre, in Glasgow: events with NHS Scotland.',
    'event',
    region: 'Scotland',
  ),
  Community(
    'Life Sciences Hub Wales',
    'https://lshubwales.com/events',
    'Works with NHS Wales on new ideas in health and care; events from Cardiff Bay.',
    'event',
    region: 'Wales',
  ),
];
