CREATE TABLE [Processing].[Test_Customers] (
    [FanID]            INT            NOT NULL,
    [ProxyUserID]      VARBINARY (32) NULL,
    [CompositeID]      BIGINT         NULL,
    [ClubID]           INT            NULL,
    [PostcodeDistrict] VARCHAR (10)   NULL,
    [SourceUID]        VARCHAR (20)   NULL,
    [rw]               INT            NULL,
    [PostalArea]       VARCHAR (4)    NULL,
    [CINID]            INT            NULL,
    [Chksum]           INT            NULL,
    [isNew]            BIT            NULL
);

