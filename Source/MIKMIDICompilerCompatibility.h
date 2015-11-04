//
//  MIKMIDICompilerCompatibility.h
//  MIKMIDI
//
//  Created by Andrew Madsen on 11/4/15.
//  Copyright © 2015 Mixed In Key. All rights reserved.
//

/*
 This header contains macros used to adopt new compiler features without breaking support for building MIKMIDI
 with older compiler versions.
 */

// Keep older versions of the compiler happy
#ifndef NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_END
#define nullable
#define nonnullable
#define __nullable
#endif

#ifndef MIKArrayOf
#if __has_feature(objc_generics)
#define MIKArrayOf(TYPE) NSArray<TYPE>
#define MIKArrayOfKindOf(TYPE) NSArray<__kindof TYPE>
#else
#define MIKArrayOf(TYPE) NSArray
#define MIKArrayOfKindOf(TYPE) NSArray
#endif
#endif // #ifndef MIKArrayOf
