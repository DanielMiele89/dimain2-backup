﻿CREATE TABLE [InsightArchive].[NewsletterBucketBData] (
    [FanID]            INT  NOT NULL,
    [SmartEmailSendID] INT  NOT NULL,
    [Offer1]           INT  NOT NULL,
    [Offer2]           INT  NOT NULL,
    [Offer3]           INT  NOT NULL,
    [Offer4]           INT  NOT NULL,
    [Offer5]           INT  NOT NULL,
    [Offer6]           INT  NOT NULL,
    [Offer7]           INT  NOT NULL,
    [Offer1StartDate]  DATE NULL,
    [Offer2StartDate]  DATE NULL,
    [Offer3StartDate]  DATE NULL,
    [Offer4StartDate]  DATE NULL,
    [Offer5StartDate]  DATE NULL,
    [Offer6StartDate]  DATE NULL,
    [Offer7StartDate]  DATE NULL,
    [Offer1EndDate]    DATE NULL,
    [Offer2EndDate]    DATE NULL,
    [Offer3EndDate]    DATE NULL,
    [Offer4EndDate]    DATE NULL,
    [Offer5EndDate]    DATE NULL,
    [Offer6EndDate]    DATE NULL,
    [Offer7EndDate]    DATE NULL
);


GO
CREATE CLUSTERED INDEX [cix_NewsletterBucketBData_FanID]
    ON [InsightArchive].[NewsletterBucketBData]([FanID] ASC);

