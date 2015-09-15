//
//  AKLinearTransformation.swift
//  AudioKit
//
//  Autogenerated by scripts by Aurelius Prochazka on 9/13/15.
//  Copyright (c) 2015 Aurelius Prochazka. All rights reserved.
//

import Foundation

/** Linear tranformation from one range to another, based on minimum and maximum values.

This module scales from one range to another defined by a minimum and maximum point in the input and output domain.
*/
@objc class AKLinearTransformation : AKParameter {

    // MARK: - Properties

    private var scale = UnsafeMutablePointer<sp_scale>.alloc(1)

    private var input = AKParameter()


    /** Minimum value to scale from. [Default Value: -1] */
    var minimumInput: AKParameter = akp(-1) {
        didSet {
            minimumInput.bind(&scale.memory.inmin)
            dependencies.append(minimumInput)
        }
    }

    /** Maximum value to scale from. [Default Value: 1] */
    var maximumInput: AKParameter = akp(1) {
        didSet {
            maximumInput.bind(&scale.memory.inmax)
            dependencies.append(maximumInput)
        }
    }

    /** Minimum value to scale to. [Default Value: 0] */
    var minimumOutput: AKParameter = akp(0) {
        didSet {
            minimumOutput.bind(&scale.memory.outmin)
            dependencies.append(minimumOutput)
        }
    }

    /** Maximum value to scale to. [Default Value: 1] */
    var maximumOutput: AKParameter = akp(1) {
        didSet {
            maximumOutput.bind(&scale.memory.outmax)
            dependencies.append(maximumOutput)
        }
    }


    // MARK: - Initializers

    /** Instantiates the scaled value with default values

    - parameter input: Input audio signal. 
    */
    init(input sourceInput: AKParameter)
    {
        super.init()
        input = sourceInput
        setup()
        dependencies = [input]
        bindAll()
    }

    /** Instantiates the scaled value with all values

    - parameter input: Input signal. 
    - parameter minimumInput: Minimum value to scale from. [Default Value: -1]
    - parameter maximumInput: Maximum value to scale from. [Default Value: 1]
    - parameter minimumOutput: Minimum value to scale to. [Default Value: 0]
    - parameter maximumOutput: Maximum value to scale to. [Default Value: 1]
    */
    convenience init(
        input         sourceInput: AKParameter,
        minimumInput  inminInput:  AKParameter,
        maximumInput  inmaxInput:  AKParameter,
        minimumOutput outminInput: AKParameter,
        maximumOutput outmaxInput: AKParameter)
    {
        self.init(input: sourceInput)
        minimumInput  = inminInput
        maximumInput  = inmaxInput
        minimumOutput = outminInput
        maximumOutput = outmaxInput

        bindAll()
    }

    // MARK: - Internals

    /** Bind every property to the internal scaled value */
    internal func bindAll() {
        minimumInput .bind(&scale.memory.inmin)
        maximumInput .bind(&scale.memory.inmax)
        minimumOutput.bind(&scale.memory.outmin)
        maximumOutput.bind(&scale.memory.outmax)
        dependencies.append(minimumInput)
        dependencies.append(maximumInput)
        dependencies.append(minimumOutput)
        dependencies.append(maximumOutput)
    }

    /** Internal set up function */
    internal func setup() {
        sp_scale_create(&scale)
        sp_scale_init(AKManager.sharedManager.data, scale)
    }

    /** Computation of the next value */
    override func compute() {
        sp_scale_compute(AKManager.sharedManager.data, scale, &(input.leftOutput), &leftOutput);
        sp_scale_compute(AKManager.sharedManager.data, scale, &(input.rightOutput), &rightOutput);
    }

    /** Release of memory */
    override func teardown() {
        sp_scale_destroy(&scale)
    }
}
