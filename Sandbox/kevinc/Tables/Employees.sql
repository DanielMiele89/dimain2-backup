CREATE TABLE [kevinc].[Employees] (
    [empid]           INT           IDENTITY (1, 1) NOT NULL,
    [lastname]        NVARCHAR (20) NOT NULL,
    [firstname]       NVARCHAR (10) NOT NULL,
    [title]           NVARCHAR (30) NOT NULL,
    [titleofcourtesy] NVARCHAR (25) NOT NULL,
    [birthdate]       DATETIME      NOT NULL,
    [hiredate]        DATETIME      NOT NULL,
    [address]         NVARCHAR (60) NOT NULL,
    [city]            NVARCHAR (15) NOT NULL,
    [region]          NVARCHAR (15) NULL,
    [postalcode]      NVARCHAR (10) NULL,
    [country]         NVARCHAR (15) NOT NULL,
    [phone]           NVARCHAR (24) NOT NULL,
    [mgrid]           INT           NULL,
    CONSTRAINT [PK_Employees] PRIMARY KEY CLUSTERED ([empid] ASC),
    CONSTRAINT [CHK_birthdate] CHECK ([birthdate]<=getdate()),
    CONSTRAINT [FK_Employees_Employees] FOREIGN KEY ([mgrid]) REFERENCES [kevinc].[Employees] ([empid])
);


GO
CREATE NONCLUSTERED INDEX [idx_nc_lastname]
    ON [kevinc].[Employees]([lastname] ASC);


GO
CREATE NONCLUSTERED INDEX [idx_nc_postalcode]
    ON [kevinc].[Employees]([postalcode] ASC);

