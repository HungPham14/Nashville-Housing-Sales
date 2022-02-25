--DATA CLEANING--

Select *
from PortfolioProjects.dbo.NashvilleHousingSales

--1. Standardlize the Data Format
Select SaleDate from PortfolioProjects.dbo.NashvilleHousingSales

Select convert(date, SaleDate) from PortfolioProjects.dbo.NashvilleHousingSales

Alter Table PortfolioProjects.dbo.NashvilleHousingSales
ADD SaleDateAltered date 

UPDATE PortfolioProjects.dbo.NashvilleHousingSales
SET SaleDateAltered = CONVERT(date, SaleDate)

Alter Table PortfolioProjects.dbo.NashvilleHousingSales
DROP COLUMN SaleDate

Select *
from PortfolioProjects.dbo.NashvilleHousingSales



--------------------------------------------------------------------------------
--2. Populate the Property Address Data
Select *
from PortfolioProjects.dbo.NashvilleHousingSales
where PropertyAddress is null
order by ParcelID

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, isnull(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProjects.dbo.NashvilleHousingSales a
JOIN PortfolioProjects.dbo.NashvilleHousingSales b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
	where a.PropertyAddress is null

UPDATE a
SET PropertyAddress = isnull(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProjects.dbo.NashvilleHousingSales a
JOIN PortfolioProjects.dbo.NashvilleHousingSales b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
	where a.PropertyAddress is null


---------------------------------------------------------------------------------
--3. Breaking out the Address into seperate column (Address, City, State) 
--3.1 Using Lambda in Python
--3.2 Using SUBSTRING(), CHARINDEX() in SQL
Select PropertyAddress, OwnerAddress, 
	substring(PropertyAddress, 1, charindex(',', PropertyAddress) -1) as PropertySplitAddress,
	substring(PropertyAddress, charindex(',', PropertyAddress) +1, len(PropertyAddress)) as PropertySplitCity,
from PortfolioProjects.dbo.NashvilleHousingSales

--3.3 Using PARSENAME(), REPLACE() in SQL
Select PropertyAddress, OwnerAddress, 
	parsename(replace(PropertyAddress, ',', '.'), 1) as PropertySplitCity,
	parsename(replace(PropertyAddress, ',', '.'), 2) as PropertySplitAddress,
	parsename(replace(OwnerAddress, ',', '.'), 1) as OwnerSplitState, 
	parsename(replace(OwnerAddress, ',', '.'), 2) as OwnerSplitCity,
	parsename(replace(OwnerAddress, ',', '.'), 3) as OwnerSplitAddress
from PortfolioProjects.dbo.NashvilleHousingSales

Alter Table PortfolioProjects.dbo.NashvilleHousingSales
ADD PropertySplitCity Nvarchar(255),
	PropertySplitAddress Nvarchar(255),
	OwnerSplitState Nvarchar(255),
	OwnerSplitCity Nvarchar(255),
	OwnerSplitAddress Nvarchar(255)

UPDATE PortfolioProjects.dbo.NashvilleHousingSales
SET PropertySplitCity = parsename(replace(PropertyAddress, ',', '.'), 1),
	PropertySplitAddress = parsename(replace(PropertyAddress, ',', '.'), 2),
	OwnerSplitState = parsename(replace(OwnerAddress, ',', '.'), 1),
	OwnerSplitCity = parsename(replace(OwnerAddress, ',', '.'), 2),
	OwnerSplitAddress = parsename(replace(OwnerAddress, ',', '.'), 3)


--4. Change Y & N into Yes & No in the [SoldAsVacant] field
UPDATE PortfolioProjects.dbo.NashvilleHousingSales
SET SoldAsVacant = REPLACE(SoldAsVacant, 'N', 'No')

UPDATE PortfolioProjects.dbo.NashvilleHousingSales
SET SoldAsVacant = REPLACE(SoldAsVacant, 'Y', 'Yes')

UPDATE PortfolioProjects.dbo.NashvilleHousingSales
SET SoldAsVacant = REPLACE(SoldAsVacant, 'Noo', 'No')

UPDATE PortfolioProjects.dbo.NashvilleHousingSales
SET SoldAsVacant = REPLACE(SoldAsVacant, 'Yeses', 'Yes')

select Distinct(SoldAsVacant), Count(SoldAsVacant)
from PortfolioProjects.dbo.NashvilleHousingSales
group by SoldAsVacant

--4.2 Using CASE statement
Select SoldAsVacant,
	CASE When SoldAsVacant = 'Y' THEN 'Yes'
		 When SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
	END	
from PortfolioProjects.dbo.NashvilleHousingSales

UPDATE PortfolioProjects.dbo.NashvilleHousingSales
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
						When SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END	

--5. Remove Duplicate
With temp_table as
	(select *,  ROW_NUMBER() OVER ( Partition by ParcelID, PropertyAddress, SalePrice, SaleDateAltered, LegalReference order by UniqueID) as row_num
	from PortfolioProjects.dbo.NashvilleHousingSales)

select * 
from temp_table
where row_num > 1


With temp_table as
	(select *,  ROW_NUMBER() OVER ( Partition by ParcelID, PropertyAddress, SalePrice, SaleDateAltered, LegalReference order by UniqueID) as row_num
	from PortfolioProjects.dbo.NashvilleHousingSales)

delete
from temp_table
where row_num > 1


--6. Delete Unused Columns
select *
from PortfolioProjects.dbo.NashvilleHousingSales

Alter Table PortfolioProjects.dbo.NashvilleHousingSales
DROP COLUMN PropertyAddress, OwnerAddress


---------------------------------------------------------------------------------------------------------------------
