//
/*
Copyright 2021 Splunk Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// Why not "import SplunkOtelCrashReporting"?  Because this is linked as a local library and not as a swift package
// FIXME align the library name, file structure, etc. with the new swift package name
@testable import SplunkRumCrashReporting
import SplunkOtel
import Foundation
import XCTest

var localSpans: [SpanData] = []

class TestSpanExporter: SpanExporter {
    var exportSucceeds = true

    func export(spans: [SpanData]) -> SpanExporterResultCode {
        if exportSucceeds {
            localSpans.append(contentsOf: spans)
            return .success
        } else {
            return .failure
        }
    }

    func flush() -> SpanExporterResultCode { return .success }
    func shutdown() { }
}

class CrashTests: XCTestCase {
    func testBasics_v1() throws {
        let crashPath = Bundle(for: CrashTests.self).url(forResource: "sample_v1", withExtension: "plcrash")!
        let crashData = try Data(contentsOf: crashPath)

        SplunkRumBuilder(beaconUrl: "http://127.0.0.1:8989/v1/traces", rumAuth: "FAKE")
            .allowInsecureBeacon(enabled: true)
            .debug(enabled: true)
            .build()
        let tracerProvider = TracerProviderBuilder()
            .add(spanProcessor: SimpleSpanProcessor(spanExporter: TestSpanExporter()))
            .build()
        OpenTelemetry.registerTracerProvider(tracerProvider: tracerProvider)
        localSpans.removeAll()

        SplunkRumCrashReporting.start()
        try loadPendingCrashReport(crashData)

        let crashReport = localSpans.first(where: { (span) -> Bool in
            return span.name == "SIGILL"
        })
        let startup = localSpans.first(where: { (span) -> Bool in
            return span.name == "SplunkRumCrashReporting"
        })

        XCTAssertNotNil(crashReport)
        XCTAssertEqual(crashReport!.attributes["crash.address"]?.description, "140733995048756")
        XCTAssertEqual(crashReport!.attributes["component"]?.description, "crash")
        XCTAssertEqual(crashReport!.attributes["error"]?.description, "true")
        XCTAssertEqual(crashReport!.attributes["exception.type"]?.description, "SIGILL")
        XCTAssertNotNil(startup)
        XCTAssertEqual(startup!.attributes["component"]?.description, "appstart")

    }
    func testBasics_v2() throws {
        let crashPath = Bundle(for: CrashTests.self).url(forResource: "sample_v2", withExtension: "plcrash")!
        let crashData = try Data(contentsOf: crashPath)

        SplunkRumBuilder(beaconUrl: "http://127.0.0.1:8989/v1/traces", rumAuth: "FAKE")
            .allowInsecureBeacon(enabled: true)
            .debug(enabled: true)
            .build()
        let tracerProvider = TracerProviderBuilder()
            .add(spanProcessor: SimpleSpanProcessor(spanExporter: TestSpanExporter()))
            .build()
        OpenTelemetry.registerTracerProvider(tracerProvider: tracerProvider)
        localSpans.removeAll()

        SplunkRumCrashReporting.start()
        try loadPendingCrashReport(crashData)

        let crashReport = localSpans.first(where: { (span) -> Bool in
            return span.name == "SIGTRAP"
        })
        let startup = localSpans.first(where: { (span) -> Bool in
            return span.name == "SplunkRumCrashReporting"
        })

        XCTAssertNotNil(crashReport)
        XCTAssertEqual(crashReport!.attributes["crash.address"]?.description, "7595465412")
        XCTAssertEqual(crashReport!.attributes["component"]?.description, "crash")
        XCTAssertEqual(crashReport!.attributes["error"]?.description, "true")
        XCTAssertEqual(crashReport!.attributes["exception.type"]?.description, "SIGTRAP")
        XCTAssertEqual(crashReport!.attributes["crash.batteryLevel"]?.description, "91.0%")
        XCTAssertEqual(crashReport!.attributes["crash.freeDiskSpace"]?.description, "197.23 GB")
        XCTAssertEqual(crashReport!.attributes["crash.freeMemory"]?.description, "5.54 GB")

        XCTAssertNotNil(startup)
        XCTAssertEqual(startup!.attributes["component"]?.description, "appstart")

    }
    func testBasics_v3() throws {
        let crashPath = Bundle(for: CrashTests.self).url(forResource: "sample_v3", withExtension: "plcrash")!
        let crashData = try Data(contentsOf: crashPath)

        SplunkRumBuilder(beaconUrl: "http://127.0.0.1:8989/v1/traces", rumAuth: "FAKE")
            .allowInsecureBeacon(enabled: true)
            .debug(enabled: true)
            .build()
        let tracerProvider = TracerProviderBuilder()
            .add(spanProcessor: SimpleSpanProcessor(spanExporter: TestSpanExporter()))
            .build()
        OpenTelemetry.registerTracerProvider(tracerProvider: tracerProvider)
        localSpans.removeAll()

        SplunkRumCrashReporting.start()
        try loadPendingCrashReport(crashData)

        let crashReport = localSpans.first(where: { (span) -> Bool in
            return span.name == "SIGTRAP"
        })
        let startup = localSpans.first(where: { (span) -> Bool in
            return span.name == "SplunkRumCrashReporting"
        })

        XCTAssertNotNil(crashReport)
        XCTAssertEqual(crashReport!.attributes["crash.address"]?.description, "6786470812")
        XCTAssertEqual(crashReport!.attributes["component"]?.description, "crash")
        XCTAssertEqual(crashReport!.attributes["error"]?.description, "true")
        XCTAssertEqual(crashReport!.attributes["exception.type"]?.description, "SIGTRAP")
        XCTAssertEqual(crashReport!.attributes["crash.batteryLevel"]?.description, "100.0%")
        XCTAssertEqual(crashReport!.attributes["crash.freeDiskSpace"]?.description, "628.03 GB")
        XCTAssertEqual(crashReport!.attributes["crash.freeMemory"]?.description, "31.88 GB")
        XCTAssertEqual(crashReport!.attributes["crash.app.version"]?.description, "1.0")
        XCTAssertNotNil(crashReport!.attributes["exception.threads"])
        XCTAssertTrue(crashReport!.attributes["exception.threads"]?.description.contains("threadNumber") ?? false)
        XCTAssertTrue(crashReport!.attributes["exception.threads"]?.description.contains("crashed") ?? false)
        XCTAssertTrue(crashReport!.attributes["exception.threads"]?.description.contains("instructionPointer") ?? false)
        XCTAssertTrue(crashReport!.attributes["exception.threads"]?.description.contains("baseAddress") ?? false)
        XCTAssertTrue(crashReport!.attributes["exception.threads"]?.description.contains("imageName") ?? false)
        XCTAssertTrue(crashReport!.attributes["exception.threads"]?.description.contains("offset") ?? false)
        XCTAssertNotNil(crashReport!.attributes["exception.images"])
        XCTAssertTrue(crashReport!.attributes["exception.images"]?.description.contains("imageUUID") ?? false)
        XCTAssertTrue(crashReport!.attributes["exception.images"]?.description.contains("imageSize") ?? false)
        XCTAssertTrue(crashReport!.attributes["exception.images"]?.description.contains("imagePath") ?? false)
        XCTAssertTrue(crashReport!.attributes["exception.images"]?.description.contains("baseAddress") ?? false)

        XCTAssertNotNil(startup)
        XCTAssertEqual(startup!.attributes["component"]?.description, "appstart")

    }
}
