//
//  Config.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//
//  Compile-time configurations.  Should all be zero for deployment

#ifndef AirBitz_Config_h
#define AirBitz_Config_h

/* These should be 0 for deployment */
#define DIRECTORY_ONLY					0	/* set to 0 for wallet and directory, set to 1 for just directory */
#define SKIP_PW_VALIDATION_CHECKS		0	/* skip password signup validation (allows user to enter anything) */
#define HARD_CODED_LOGIN				1	/* set to 1 to auto login with credientials below (used for testing) */

#define HARD_CODED_LOGIN_NAME			@"201404062"
#define HARD_CODED_LOGIN_PASSWORD		@"Carson Whitsett1"

#endif
