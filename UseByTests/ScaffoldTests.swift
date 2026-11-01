import Testing
@testable import UseBy

@Suite("Scaffold")
struct ScaffoldTests {
    @Test("App and widget share the same App Group")
    func appGroupIdentifier() {
        #expect(AppGroup.identifier == "group.com.usebyapp.UseBy")
    }
}
