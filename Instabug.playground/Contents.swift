import UIKit
import XCTest

class Bug {
    enum State {
        case open
        case closed
    }
    
    let state: State
    let timestamp: Date
    let comment: String
    
    init(state: State, timestamp: Date, comment: String) {
        self.comment = comment
        self.state = state
        self.timestamp = timestamp
    }
    
    init(jsonString: String) throws {
        
        let json = jsonParse(string: jsonString)
        
        let tempState = json["state"]!
        
        if tempState == "open" {
            self.state = .open
        } else {
            self.state = .closed
        }
        
        self.comment = json["comment"]!
        
        let timeStr = json["timestamp"]!
        let time = (timeStr as NSString).doubleValue
        self.timestamp = Date(timeIntervalSince1970: time)
    }
}

func jsonParse(string: String) -> [String:String] {
    
    let separators = CharacterSet(charactersIn: ",\":}{")
    let arr = string.components(separatedBy: separators)
    
    var json = [String]()
    for a in arr {
        if a != "" && a != " " {
            json.append(a)
        }
    }
    
    var dict = [String:String]()
    
    dict[json[0]] = json[1]
    dict[json[2]] = json[3]
    dict[json[4]] = json[5]
    
    return dict
}

enum TimeRange {
    case pastDay
    case pastWeek
    case pastMonth
}

class Application {
    var bugs: [Bug]
    
    init(bugs: [Bug]) {
        self.bugs = bugs
    }
    
    func findBugs(state: Bug.State?, timeRange: TimeRange) -> [Bug] {
        
        var filteredBugs = [Bug]()
        var days: Double!
        if timeRange == .pastDay {
            days = 1
        } else if timeRange == .pastWeek {
            days = 7
        } else if timeRange == .pastMonth {
            days = 30
        }
        
        for bug in bugs {
            if bug.state == state && dayDifference(from: bug.timestamp.timeIntervalSince1970) <= days {
                filteredBugs.append(bug)
            }
        }
        return filteredBugs
    }
    
    func dayDifference(from interval : TimeInterval) -> Double    {
        let calendar = NSCalendar.current
        let startOfNow = Date()
        let startOfTimeStamp = Date(timeIntervalSince1970: interval)
        let components = calendar.dateComponents([.hour], from: startOfNow, to: startOfTimeStamp)
        let day = Double((components.hour!)+1)/24
        return abs(day)
    }
}

class UnitTests : XCTestCase {
    lazy var bugs: [Bug] = {
        var date26HoursAgo = Date()
        date26HoursAgo.addTimeInterval(-1 * (26 * 60 * 60))
        
        var date2WeeksAgo = Date()
        date2WeeksAgo.addTimeInterval(-1 * (14 * 24 * 60 * 60))
        
        let bug1 = Bug(state: .open, timestamp: Date(), comment: "Bug 1")
        let bug2 = Bug(state: .open, timestamp: date26HoursAgo, comment: "Bug 2")
        let bug3 = Bug(state: .closed, timestamp: date2WeeksAgo, comment: "Bug 2")

        return [bug1, bug2, bug3]
    }()
    
    lazy var application: Application = {
        let application = Application(bugs: self.bugs)
        return application
    }()

    func testFindOpenBugsInThePastDay() {
        let bugs = application.findBugs(state: .open, timeRange: .pastDay)
        XCTAssertTrue(bugs.count == 1, "Invalid number of bugs")
        XCTAssertEqual(bugs[0].comment, "Bug 1", "Invalid bug order")
    }
    
    func testFindClosedBugsInThePastMonth() {
        let bugs = application.findBugs(state: .closed, timeRange: .pastMonth)
        
        XCTAssertTrue(bugs.count == 1, "Invalid number of bugs")
    }
    
    func testFindClosedBugsInThePastWeek() {
        let bugs = application.findBugs(state: .closed, timeRange: .pastWeek)
        
        XCTAssertTrue(bugs.count == 0, "Invalid number of bugs")
    }
    
    func testInitializeBugWithJSON() {
        do {
            let json = "{\"state\": \"open\",\"timestamp\": 1493393946,\"comment\": \"Bug via JSON\"}"

            let bug = try Bug(jsonString: json)
            
            XCTAssertEqual(bug.comment, "Bug via JSON")
            XCTAssertEqual(bug.state, .open)
            XCTAssertEqual(bug.timestamp, Date(timeIntervalSince1970: 1493393946))
        } catch {
            print(error)
        }
    }
}

class PlaygroundTestObserver : NSObject, XCTestObservation {
    @objc func testCase(_ testCase: XCTestCase, didFailWithDescription description: String, inFile filePath: String?, atLine lineNumber: UInt) {
        print("Test failed on line \(lineNumber): \(String(describing: testCase.name)), \(description)")
    }
}

let observer = PlaygroundTestObserver()
let center = XCTestObservationCenter.shared()
center.addTestObserver(observer)

TestRunner().runTests(testClass: UnitTests.self)
