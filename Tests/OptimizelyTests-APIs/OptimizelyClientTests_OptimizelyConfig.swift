/****************************************************************************
* Copyright 2019, Optimizely, Inc. and contributors                        *
*                                                                          *
* Licensed under the Apache License, Version 2.0 (the "License");          *
* you may not use this file except in compliance with the License.         *
* You may obtain a copy of the License at                                  *
*                                                                          *
*    http://www.apache.org/licenses/LICENSE-2.0                            *
*                                                                          *
* Unless required by applicable law or agreed to in writing, software      *
* distributed under the License is distributed on an "AS IS" BASIS,        *
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
* See the License for the specific language governing permissions and      *
* limitations under the License.                                           *
***************************************************************************/
    

import XCTest

class OptimizelyClientTests_OptimizelyConfig: XCTestCase {

    var optimizely: OptimizelyClient!

    override func setUp() {
        super.setUp()
        
        let datafile = OTUtils.loadJSONDatafile("optimizely_config")!
        
        self.optimizely = OptimizelyClient(sdkKey: "12345",
                                           userProfileService: OTUtils.createClearUserProfileService())
        try! self.optimizely.start(datafile: datafile)
    }
    
    override func tearDown() {
    }
    
    func testGetOptimizelyConfig_ExperimentsMap() {
        print("------------------------------------------------------")
        let optimizelyConfig = try! optimizely.getOptimizelyConfig()
        
        print("   Experiments: \(optimizelyConfig.experimentsMap.keys)")

        XCTAssertEqual(optimizelyConfig.experimentsMap.count, 5)

        let experiment1 = optimizelyConfig.experimentsMap["exp_with_audience"]!
        let experiment2 = optimizelyConfig.experimentsMap["experiment_4000"]!
        
        XCTAssertEqual(experiment1.variationsMap.count, 2)
        XCTAssertEqual(experiment2.variationsMap.count, 2)
        
        print("   Experiment1 > Variations: \(experiment1.variationsMap.keys)")
        print("   Experiment2 > Variations: \(experiment2.variationsMap.keys)")
        
        let variation1 = experiment1.variationsMap["a"]!
        let variation2 = experiment1.variationsMap["b"]!

        XCTAssertEqual(variation1.variablesMap.count, 0)
        XCTAssertEqual(variation2.variablesMap.count, 0)
        print("------------------------------------------------------")
    }
    
    func testGetOptimizelyConfig_FeatureFlagsMap() {
        print("------------------------------------------------------")
        let optimizelyConfig = try! optimizely.getOptimizelyConfig()
        
        print("   Features: \(optimizelyConfig.featureFlagsMap.keys)")
        
        XCTAssertEqual(optimizelyConfig.featureFlagsMap.count, 2)
        
        let feature1 = optimizelyConfig.featureFlagsMap["mutex_group_feature"]!
        let feature2 = optimizelyConfig.featureFlagsMap["feature_exp_no_traffic"]!

        // FeatureFlag: experimentsMap
        
        XCTAssertEqual(feature1.experimentsMap.count, 2)
        XCTAssertEqual(feature2.experimentsMap.count, 1)

        print("   Feature1 > Experiments: \(feature1.experimentsMap.keys)")
        print("   Feature2 > Experiments: \(feature2.experimentsMap.keys)")

        let experiment1 = feature1.experimentsMap["experiment_4000"]!
        let experiment2 = feature1.experimentsMap["experiment_8000"]!
        
        XCTAssertEqual(experiment1.variationsMap.count, 2)
        XCTAssertEqual(experiment2.variationsMap.count, 1)

        print("   Feature1 > Experiment1 > Variations: \(experiment1.variationsMap.keys)")
        print("   Feature1 > Experiment2 > Variations: \(experiment2.variationsMap.keys)")
        
        let variation1 = experiment1.variationsMap["all_traffic_variation_exp_1"]!
        let variation2 = experiment1.variationsMap["no_traffic_variation_exp_1"]!

        XCTAssertEqual(variation1.variablesMap.count, 4)
        XCTAssertEqual(variation2.variablesMap.count, 0)

        print("   Feature1 > Experiment1 > Variation1 > Variables: \(variation1.variablesMap.keys)")
        print("   Feature1 > Experiment1 > Variation2 > Variables: \(variation2.variablesMap.keys)")
        
        let variable1 = variation1.variablesMap["s_foo"]!
        XCTAssertEqual(variable1.id, "2687470097")
        XCTAssertEqual(variable1.key, "s_foo")
        XCTAssertEqual(variable1.type, "string")
        XCTAssertEqual(variable1.value, "s1")

        // FeatureFlag: variablesMap
        
        XCTAssertEqual(feature1.variablesMap.count, 4)
        XCTAssertEqual(feature2.variablesMap.count, 0)

        print("   Feature1 > FeatureVariables: \(feature1.variablesMap.keys)")
        
        let featureVariable = feature1.variablesMap["i_42"]!
        XCTAssertEqual(featureVariable.id, "2687470094")
        XCTAssertEqual(featureVariable.key, "i_42")
        XCTAssertEqual(featureVariable.type, "integer")
        XCTAssertEqual(featureVariable.value, "42")
        print("------------------------------------------------------")
    }

}
