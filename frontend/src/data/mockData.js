// Mock Data for GOALSIGHT Application

export const mockLiveMatches = [{
        id: 1,
        league: {
            name: 'Premier League',
            country: 'England',
            logo: 'https://cdn.sportmonks.com/images/soccer/leagues/7.png'
        },
        round: 'Round 26',
        home: {
            id: 1,
            name: 'Manchester United',
            logo: 'https://cdn.sportmonks.com/images/soccer/teams/31/2087.png',
            score: 2
        },
        away: {
            id: 2,
            name: 'Liverpool',
            logo: 'https://cdn.sportmonks.com/images/soccer/teams/14/2062.png',
            score: 1
        },
        status: 'LIVE',
        minute: 67,
        startTime: new Date().toISOString(),
        events: [{
                minute: 23,
                type: 'Goal',
                player: 'Bruno Fernandes',
                team: 'home',
                injuryTime: null
            },
            {
                minute: 45,
                type: 'Goal',
                player: 'Mohamed Salah',
                team: 'away',
                injuryTime: 2
            },
            {
                minute: 62,
                type: 'Goal',
                player: 'Marcus Rashford',
                team: 'home',
                injuryTime: null
            }
        ]
    },
    {
        id: 2,
        league: {
            name: 'La Liga',
            country: 'Spain',
            logo: 'https://cdn.sportmonks.com/images/soccer/leagues/8.png'
        },
        round: 'Round 24',
        home: {
            id: 3,
            name: 'Real Madrid',
            logo: 'https://cdn.sportmonks.com/images/soccer/teams/22/2710.png',
            score: 1
        },
        away: {
            id: 4,
            name: 'Barcelona',
            logo: 'https://cdn.sportmonks.com/images/soccer/teams/6/2694.png',
            score: 1
        },
        status: 'HT',
        minute: 45,
        startTime: new Date(Date.now() - 3600000).toISOString(),
        events: [{
                minute: 15,
                type: 'Goal',
                player: 'Vinicius Junior',
                team: 'home',
                injuryTime: null
            },
            {
                minute: 38,
                type: 'Goal',
                player: 'Robert Lewandowski',
                team: 'away',
                injuryTime: null
            }
        ]
    },
    {
        id: 3,
        league: {
            name: 'Serie A',
            country: 'Italy',
            logo: 'https://cdn.sportmonks.com/images/soccer/leagues/5.png'
        },
        round: 'Round 25',
        home: {
            id: 5,
            name: 'Juventus',
            logo: 'https://cdn.sportmonks.com/images/soccer/teams/28/2716.png',
            score: 3
        },
        away: {
            id: 6,
            name: 'Inter Milan',
            logo: 'https://cdn.sportmonks.com/images/soccer/teams/4/2692.png',
            score: 2
        },
        status: 'LIVE',
        minute: 89,
        startTime: new Date(Date.now() - 5400000).toISOString(),
        events: [{
                minute: 12,
                type: 'Goal',
                player: 'Dusan Vlahovic',
                team: 'home',
                injuryTime: null
            },
            {
                minute: 28,
                type: 'Goal',
                player: 'Lautaro Martinez',
                team: 'away',
                injuryTime: null
            },
            {
                minute: 55,
                type: 'Goal',
                player: 'Federico Chiesa',
                team: 'home',
                injuryTime: null
            },
            {
                minute: 71,
                type: 'Goal',
                player: 'Marcus Thuram',
                team: 'away',
                injuryTime: null
            },
            {
                minute: 85,
                type: 'Goal',
                player: 'Dusan Vlahovic',
                team: 'home',
                injuryTime: null
            }
        ]
    }
]

export const mockTodayMatches = [{
        id: 7,
        league: 'Premier League',
        homeTeam: 'Chelsea',
        awayTeam: 'Arsenal',
        homeScore: null,
        awayScore: null,
        time: '15:00',
        status: 'Scheduled'
    },
    {
        id: 8,
        league: 'Bundesliga',
        homeTeam: 'Bayern Munich',
        awayTeam: 'Borussia Dortmund',
        homeScore: null,
        awayScore: null,
        time: '17:30',
        status: 'Scheduled'
    },
    {
        id: 9,
        league: 'Ligue 1',
        homeTeam: 'PSG',
        awayTeam: 'Marseille',
        homeScore: null,
        awayScore: null,
        time: '20:00',
        status: 'Scheduled'
    }
]

export const mockRecentResults = [{
        id: 10,
        league: 'Premier League',
        homeTeam: 'Manchester City',
        awayTeam: 'Tottenham',
        homeScore: 3,
        awayScore: 1,
        date: '2 days ago',
        status: 'FT'
    },
    {
        id: 11,
        league: 'La Liga',
        homeTeam: 'Atletico Madrid',
        awayTeam: 'Sevilla',
        homeScore: 2,
        awayScore: 2,
        date: '1 day ago',
        status: 'FT'
    },
    {
        id: 12,
        league: 'Serie A',
        homeTeam: 'AC Milan',
        awayTeam: 'Napoli',
        homeScore: 1,
        awayScore: 3,
        date: '3 days ago',
        status: 'FT'
    }
]

export const mockHighlights = [{
        id: 'h1',
        title: 'Manchester United vs Liverpool - All Goals & Highlights',
        thumbnail: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=400',
        duration: '5:23',
        league: 'Premier League',
        views: '1.2M'
    },
    {
        id: 'h2',
        title: 'Real Madrid vs Barcelona - El Clasico Extended Highlights',
        thumbnail: 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=400',
        duration: '8:45',
        league: 'La Liga',
        views: '2.5M'
    },
    {
        id: 'h3',
        title: 'Bayern Munich - Amazing Team Goals Compilation',
        thumbnail: 'https://images.unsplash.com/photo-1560272564-c83b66b1ad12?w=400',
        duration: '6:12',
        league: 'Bundesliga',
        views: '892K'
    },
    {
        id: 'h4',
        title: 'PSG vs Marseille - Best Moments',
        thumbnail: 'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=400',
        duration: '4:58',
        league: 'Ligue 1',
        views: '654K'
    }
]

export const mockNews = [{
        id: 'n1',
        title: 'Transfer News: Star Player Signs Record Deal',
        source: 'Sky Sports',
        thumbnail: 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=400',
        date: '2 hours ago',
        category: 'Transfers'
    },
    {
        id: 'n2',
        title: 'Champions League Draw: Top Teams Face Off',
        source: 'BBC Sport',
        thumbnail: 'https://images.unsplash.com/photo-1522778119026-d647f0596c20?w=400',
        date: '5 hours ago',
        category: 'Champions League'
    },
    {
        id: 'n3',
        title: 'Injury Update: Key Players Return to Training',
        source: 'ESPN',
        thumbnail: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=400',
        date: '1 day ago',
        category: 'News'
    },
    {
        id: 'n4',
        title: 'World Cup Qualifiers: Shocking Results',
        source: 'Goal.com',
        thumbnail: 'https://images.unsplash.com/photo-1560272564-c83b66b1ad12?w=400',
        date: '1 day ago',
        category: 'International'
    }
]

export const mockFeaturedMatch = {
    league: 'Premier League',
    homeTeam: 'Manchester United',
    awayTeam: 'Liverpool',
    homeScore: 2,
    awayScore: 1,
    status: 'LIVE',
    minute: 67,
    stadium: 'Old Trafford',
    attendance: '74,310'
}

// Mock user data
export const mockUser = {
    id: 1,
    name: 'John Doe',
    email: 'john@example.com',
    avatar: 'https://ui-avatars.com/api/?name=John+Doe&background=8b5cf6&color=fff',
    favoriteTeam: 'Manchester United',
    memberSince: '2024'
}

// Simulate API delay
export const delay = (ms = 500) => new Promise(resolve => setTimeout(resolve, ms))