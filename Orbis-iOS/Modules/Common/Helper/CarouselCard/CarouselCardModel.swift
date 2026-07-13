
import Foundation

struct CardData {
    let imageName: String?
    let title: String
    let rating: Double
    let distance: String
    let description: String

    // Static method to return the predefined data
    static func sampleData() -> [CardData] {
        return [
            CardData(imageName: "beach", title: "Paradise Beach", rating: 4.8, distance: "5.6 km", description: "A beautiful white-sand beach with crystal-clear waters and excellent facilities."),
            CardData(imageName: "mountains", title: "Misty Mountains", rating: 4.7, distance: "10.2 km", description: "A serene mountain range perfect for hiking and enjoying scenic views."),
            CardData(imageName: "forest", title: "Emerald Forest", rating: 4.6, distance: "3.5 km", description: "Lush green forest with various wildlife species and peaceful walking trails."),
            CardData(imageName: "cafe", title: "Sunny Café", rating: 4.5, distance: "1.1 km", description: "A cozy spot to enjoy coffee and pastries with an outdoor seating area."),
            CardData(imageName: nil, title: "Lighthouse Point", rating: 4.4, distance: "12.0 km", description: "A historical lighthouse with breathtaking views of the ocean."),
            CardData(imageName: "restaurant", title: "Seaside Grill", rating: 4.6, distance: "0.8 km", description: "A popular restaurant known for its seafood dishes and beachside ambiance."),
            CardData(imageName: "lake", title: "Crystal Lake", rating: 4.9, distance: "7.8 km", description: "A clear, calm lake ideal for kayaking, fishing, and picnics."),
            CardData(imageName: "museum", title: "City Museum", rating: 4.3, distance: "2.4 km", description: "Explore the rich history and culture of the city with exhibits from various eras."),
            CardData(imageName: nil, title: "Sunset Park", rating: 4.5, distance: "5.0 km", description: "A well-maintained park that offers stunning sunset views over the city skyline."),
            CardData(imageName: "zoo", title: "Wildlife Zoo", rating: 4.7, distance: "9.1 km", description: "A large zoo with diverse animal species and interactive exhibits for families."),
            CardData(imageName: "stadium", title: "National Stadium", rating: 4.2, distance: "8.3 km", description: "Home to local sports events, concerts, and large-scale entertainment shows."),
            CardData(imageName: "gallery", title: "Art Gallery", rating: 4.6, distance: "2.2 km", description: "A contemporary art gallery showcasing works from both local and international artists."),
            CardData(imageName: "library", title: "Central Library", rating: 4.8, distance: "1.9 km", description: "A quiet place for reading and studying, featuring an extensive book collection."),
            CardData(imageName: "market", title: "Farmer's Market", rating: 4.7, distance: "3.6 km", description: "A bustling market with fresh produce, local crafts, and live music."),
            CardData(imageName: nil, title: "Waterfall Trail", rating: 4.9, distance: "6.5 km", description: "A scenic hiking trail that leads to a stunning waterfall."),
            CardData(imageName: "theater", title: "Grand Theater", rating: 4.4, distance: "4.1 km", description: "A classic theater featuring live performances, including plays and musicals."),
            CardData(imageName: "aquarium", title: "Oceanic Aquarium", rating: 4.8, distance: "11.3 km", description: "An impressive aquarium with diverse marine life and interactive exhibits."),
            CardData(imageName: "spa", title: "Tranquility Spa", rating: 4.5, distance: "2.7 km", description: "A peaceful retreat offering a variety of massages, facials, and relaxation therapies."),
            CardData(imageName: "garden", title: "Botanical Gardens", rating: 4.9, distance: "5.9 km", description: "A beautiful garden featuring exotic plants, flowers, and seasonal events."),
            CardData(imageName: "amusement_park", title: "Funland Amusement Park", rating: 4.6, distance: "12.5 km", description: "An exciting amusement park with thrilling rides and family-friendly attractions.")
        ]
    }
}
