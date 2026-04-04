import XCTest
import CoreLocation
@testable import SwifterX

final class GeoSortServiceTests: XCTestCase {

    private let geoSort = GeoSortService.shared

    // Reference: Atlanta downtown ~33.749, -84.388
    private let atlanta = CLLocationCoordinate2D(latitude: 33.749, longitude: -84.388)

    // Provider ~1 km away
    private let nearProvider = ServiceProvider(
        id: "near", name: "Near Pro", category: "Cleaning",
        description: "", rating: 4.5, distanceMi: 0.6,
        providerLat: 33.758, providerLng: -84.388   // ~1 km north
    )

    // Provider ~5 km away
    private let farProvider = ServiceProvider(
        id: "far", name: "Far Pro", category: "Plumbing",
        description: "", rating: 4.9, distanceMi: 3.1,
        providerLat: 33.794, providerLng: -84.388   // ~5 km north
    )

    override func setUp() {
        super.setUp()
        Task { await geoSort.update(coordinate: atlanta) }
    }

    override func tearDown() {
        Task { await geoSort.update(coordinate: nil) }
        super.tearDown()
    }

    // MARK: - Sorting

    func testNearestFirstWhenLocationAvailable() async {
        await geoSort.update(coordinate: atlanta)
        let sorted = geoSort.sorted([farProvider, nearProvider])
        XCTAssertEqual(sorted.first?.id, "near")
        XCTAssertEqual(sorted.last?.id,  "far")
    }

    func testFallsBackToRatingWhenNoLocation() async {
        await geoSort.update(coordinate: nil)
        // farProvider has higher rating (4.9 > 4.5) — should appear first
        let sorted = geoSort.sorted([nearProvider, farProvider])
        XCTAssertEqual(sorted.first?.id, "far")
    }

    func testEmptyArrayReturnsEmpty() async {
        await geoSort.update(coordinate: atlanta)
        XCTAssertTrue(geoSort.sorted([]).isEmpty)
    }

    func testSingleProviderReturnsSingle() async {
        await geoSort.update(coordinate: atlanta)
        let sorted = geoSort.sorted([nearProvider])
        XCTAssertEqual(sorted.count, 1)
        XCTAssertEqual(sorted.first?.id, "near")
    }

    // MARK: - sortedWithDistances

    func testDistancesArePositive() async {
        await geoSort.update(coordinate: atlanta)
        let pairs = geoSort.sortedWithDistances([nearProvider, farProvider])
        for pair in pairs {
            if let km = pair.km { XCTAssertGreaterThan(km, 0) }
        }
    }

    func testNearProviderHasSmallerDistance() async {
        await geoSort.update(coordinate: atlanta)
        let pairs = geoSort.sortedWithDistances([farProvider, nearProvider])
        guard let nearKm = pairs.first?.km, let farKm = pairs.last?.km else {
            XCTFail("Expected non-nil distances")
            return
        }
        XCTAssertLessThan(nearKm, farKm)
    }

    func testDistancesAreNilWithNoLocation() async {
        await geoSort.update(coordinate: nil)
        let pairs = geoSort.sortedWithDistances([nearProvider])
        XCTAssertNil(pairs.first?.km)
    }

    // MARK: - hasLocation on ServiceProvider extension

    func testProviderWithZeroCoordHasNoLocation() {
        let p = ServiceProvider(id: "z", name: "", category: "", description: "", rating: 0, distanceMi: 0)
        XCTAssertFalse(p.hasLocation)
    }

    func testProviderWithRealCoordHasLocation() {
        XCTAssertTrue(nearProvider.hasLocation)
    }
}
