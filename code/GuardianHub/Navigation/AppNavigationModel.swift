import Foundation
import Observation

@Observable
final class AppNavigationModel {
    var selectedSection: AppSection = .dashboard
}
