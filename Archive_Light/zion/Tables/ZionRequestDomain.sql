CREATE TABLE [zion].[ZionRequestDomain] (
    [ID]         INT            IDENTITY (1, 1) NOT NULL,
    [DomainName] NVARCHAR (255) NOT NULL,
    CONSTRAINT [PK_ZionRequestDomain] PRIMARY KEY CLUSTERED ([ID] ASC)
);

