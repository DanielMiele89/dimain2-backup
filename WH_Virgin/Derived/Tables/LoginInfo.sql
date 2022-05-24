CREATE TABLE [Derived].[LoginInfo] (
    [LoginInfoID]            INT           IDENTITY (1, 1) NOT NULL,
    [UserAgent]              VARCHAR (300) NOT NULL,
    [DeviceType]             VARCHAR (50)  NULL,
    [DeviceBrand]            VARCHAR (50)  NULL,
    [DeviceBrandName]        VARCHAR (50)  NULL,
    [DeviceModel]            VARCHAR (50)  NULL,
    [OSName]                 VARCHAR (50)  NULL,
    [OSVersion]              VARCHAR (30)  NULL,
    [ClientName]             VARCHAR (50)  NULL,
    [ClientShortName]        VARCHAR (50)  NULL,
    [ClientType]             VARCHAR (50)  NULL,
    [ClientVersion]          VARCHAR (30)  NULL,
    [SecondaryClientName]    VARCHAR (50)  NULL,
    [SecondaryClientType]    VARCHAR (50)  NULL,
    [SecondaryCLientVersion] VARCHAR (30)  NULL,
    [isBot]                  BIT           NULL,
    [isMobile]               BIT           NULL,
    [isDesktop]              BIT           NULL
);




GO
GRANT SELECT
    ON OBJECT::[Derived].[LoginInfo] TO [dops_useragent]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[Derived].[LoginInfo] TO [dops_useragent]
    AS [dbo];

