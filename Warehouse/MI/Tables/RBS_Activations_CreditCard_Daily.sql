﻿CREATE TABLE [MI].[RBS_Activations_CreditCard_Daily] (
    [ID]                                           INT  IDENTITY (1, 1) NOT NULL,
    [RunDate]                                      DATE CONSTRAINT [DF_MI_RBS_Activations_CreditCard_Daily] DEFAULT (getdate()) NOT NULL,
    [ActivationOnlineRegisteredPrevDayNatWest]     INT  NOT NULL,
    [ActivationOnlineUnregisteredPrevDayNatWest]   INT  NOT NULL,
    [ActivationOfflinePrevDayNatWest]              INT  NOT NULL,
    [OptOutOnlinePrevDayNatWest]                   INT  NOT NULL,
    [OptOutOfflinePrevDayNatWest]                  INT  NOT NULL,
    [DeactivationPrevDayNatWest]                   INT  NOT NULL,
    [ActivationOnlineRegisteredCumulNatWest]       INT  NOT NULL,
    [ActivationOnlineUnregisteredCumulNatWest]     INT  NOT NULL,
    [ActivationOfflineCumulNatWest]                INT  NOT NULL,
    [OptOutOnlineCumulNatWest]                     INT  NOT NULL,
    [OptOutOfflineCumulNatWest]                    INT  NOT NULL,
    [DeactivationCumulNatWest]                     INT  NOT NULL,
    [EarnersMonthNatWest]                          INT  NOT NULL,
    [EarnersCumulNatWest]                          INT  NOT NULL,
    [ActivationOnlineRegisteredPrevDayRBS]         INT  NOT NULL,
    [ActivationOnlineUnregisteredPrevDayRBS]       INT  NOT NULL,
    [ActivationOfflinePrevDayRBS]                  INT  NOT NULL,
    [OptOutOnlinePrevDayRBS]                       INT  NOT NULL,
    [OptOutOfflinePrevDayRBS]                      INT  NOT NULL,
    [DeactivationPrevDayRBS]                       INT  NOT NULL,
    [ActivationOnlineRegisteredCumulRBS]           INT  NOT NULL,
    [ActivationOnlineUnregisteredCumulRBS]         INT  NOT NULL,
    [ActivationOfflineCumulRBS]                    INT  NOT NULL,
    [OptOutOnlineCumulRBS]                         INT  NOT NULL,
    [OptOutOfflineCumulRBS]                        INT  NOT NULL,
    [DeactivationCumulRBS]                         INT  NOT NULL,
    [EarnersMonthRBS]                              INT  NOT NULL,
    [EarnersCumuRBS]                               INT  NOT NULL,
    [CCActivationOnlineRegisteredPrevDayNatWest]   INT  NOT NULL,
    [CCActivationOnlineUnregisteredPrevDayNatWest] INT  NOT NULL,
    [CCActivationOfflinePrevDayNatWest]            INT  NOT NULL,
    [CCAdditionOnlineRegisteredPrevDayNatWest]     INT  NOT NULL,
    [CCAdditionOnlineUnregisteredPrevDayNatWest]   INT  NOT NULL,
    [CCAdditionOfflinePrevDayNatWest]              INT  NOT NULL,
    [CCRemovalOnlinePrevDayNatWest]                INT  NOT NULL,
    [CCRemovalOfflinePrevDayNatWest]               INT  NOT NULL,
    [CCDeactivationPrevDayNatWest]                 INT  NOT NULL,
    [CCActivationOnlineRegisteredCumulNatWest]     INT  NOT NULL,
    [CCActivationOnlineUnregisteredCumulNatWest]   INT  NOT NULL,
    [CCActivationOfflineCumulNatWest]              INT  NOT NULL,
    [CCAdditionOnlineRegisteredCumulNatWest]       INT  NOT NULL,
    [CCAdditionOnlineUnregisteredCumulNatWest]     INT  NOT NULL,
    [CCAdditionOfflineCumulNatWest]                INT  NOT NULL,
    [CCRemovalOnlineCumulNatWest]                  INT  NOT NULL,
    [CCRemovalOfflineCumulNatWest]                 INT  NOT NULL,
    [CCDeactivationCumulNatWest]                   INT  NOT NULL,
    [CCActivationOnlineRegisteredPrevDayRBS]       INT  NOT NULL,
    [CCActivationOnlineUnregisteredPrevDayRBS]     INT  NOT NULL,
    [CCActivationOfflinePrevDayRBS]                INT  NOT NULL,
    [CCAdditionOnlineRegisteredPrevDayRBS]         INT  NOT NULL,
    [CCAdditionOnlineUnregisteredPrevDayRBS]       INT  NOT NULL,
    [CCAdditionOfflinePrevDayRBS]                  INT  NOT NULL,
    [CCRemovalOnlinePrevDayRBS]                    INT  NOT NULL,
    [CCRemovalOfflinePrevDayRBS]                   INT  NOT NULL,
    [CCDeactivationPrevDayRBS]                     INT  NOT NULL,
    [CCActivationOnlineRegisteredCumulRBS]         INT  NOT NULL,
    [CCActivationOnlineUnregisteredCumulRBS]       INT  NOT NULL,
    [CCActivationOfflineCumulRBS]                  INT  NOT NULL,
    [CCAdditionOnlineRegisteredCumulRBS]           INT  NOT NULL,
    [CCAdditionOnlineUnregisteredCumulRBS]         INT  NOT NULL,
    [CCAdditionOfflineCumulRBS]                    INT  NOT NULL,
    [CCRemovalOnlineCumulRBS]                      INT  NOT NULL,
    [CCRemovalOfflineCumulRBS]                     INT  NOT NULL,
    [CCDeactivationCumulRBS]                       INT  NOT NULL,
    CONSTRAINT [PK_MI_RBS_Activations_CreditCard_Daily] PRIMARY KEY CLUSTERED ([ID] ASC)
);
