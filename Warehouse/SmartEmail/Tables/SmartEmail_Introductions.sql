CREATE TABLE [SmartEmail].[SmartEmail_Introductions] (
    [FanID]          INT          NOT NULL,
    [Primary]        BIT          NOT NULL,
    [ClubID]         TINYINT      NOT NULL,
    [CustomerType]   VARCHAR (3)  NOT NULL,
    [DomainCombined] VARCHAR (15) NOT NULL,
    [IntroDate]      DATE         NOT NULL,
    [Bucket]         CHAR (1)     NOT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

