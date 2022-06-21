
/* Cleaning Data in SQL */

-- 1. View Table 

SELECT * 
FROM portfolio_project..nashville_housing

-- 2. Standarize Date Format 

ALTER TABLE portfolio_project..nashville_housing 
ADD SaleDateConverted Date; 

UPDATE portfolio_project..nashville_housing
SET SaleDateConverted = CONVERT (date, SaleDate);

SELECT 
	SaleDateConverted 
FROM portfolio_project..nashville_housing; 

-- 3. Populate property address data considering same ParcelID and  different UniqueID

-- 3.1. Checking first PropertyAddress nulls

SELECT *
FROM portfolio_project..nashville_housing
--WHERE PropertyAddress is null
ORDER BY ParcelID; 

-- 3.2. Joining table by same ParcelID and different Unique ID 

SELECT  
	a.ParcelID,
	a.PropertyAddress, 
	b.ParcelID, 
	b.PropertyAddress, 
	ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM portfolio_project..nashville_housing a 
JOIN portfolio_project..nashville_housing b 
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null; 

-- 3.3. Updating column PropertyAddress 

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM portfolio_project..nashville_housing a 
JOIN portfolio_project..nashville_housing b 
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null; 

-- 4. Breaking out addresses into individual columns 

-- 4.1. Breaking out Propertyaddress using SUBSTRING 

SELECT 
	SUBSTRING(PropertyAddress,1,CHARINDEX(',', PropertyAddress) -1) as Address, 
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as City
FROM portfolio_project..nashville_housing; 

-- 4.2 Creating and updating new columns PropertySplitCity and PropertyAddress

ALTER TABLE portfolio_project..nashville_housing
ADD PropertySplitAddress Nvarchar(255); 

ALTER TABLE portfolio_project..nashville_housing
ADD PropertySplitCity Nvarchar (255); 

UPDATE portfolio_project..nashville_housing
SET PropertySplitAddress  = SUBSTRING(PropertyAddress,1,CHARINDEX(',', PropertyAddress) -1) ;

UPDATE portfolio_project..nashville_housing
SET PropertySplitCity  = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

-- 4.3 Checking new columns 

SELECT 
	PropertySplitAddress, 
	PropertySplitCity
FROM portfolio_project..nashville_housing

--4.4 Breaking out OwnerAddress with PARSENAME 

SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) as Address, 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) as City,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) as State
FROM portfolio_project..nashville_housing

--4.5 Creating and updating new columns OwnerSplitAddress, OwnerSplitCity and OwnerSplitState 

ALTER TABLE portfolio_project..nashville_housing
ADD OwnerSplitAddress Nvarchar(255); 

ALTER TABLE portfolio_project..nashville_housing
ADD OwnerSplitCity Nvarchar (255); 

ALTER TABLE portfolio_project..nashville_housing
ADD OwnerSplitState Nvarchar(255); 

UPDATE portfolio_project..nashville_housing
SET OwnerSplitAddress  = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) ;

UPDATE portfolio_project..nashville_housing
SET OwnerSplitCity  = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

UPDATE portfolio_project..nashville_housing
SET OwnerSplitState  = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) ;


-- 5. Consistency in SoldAsVacant field 

-- 5.1 Checking for unique values and counting them 

Select 
	Distinct (SoldAsVacant), 
	COUNT(SoldAsVacant) as Count
FROM portfolio_project..nashville_housing
GROUP BY SoldAsVacant
ORDER BY 2

-- 5.2 Giving same format to values changing Y and N into Yes and No 

SELECT 
	SoldAsVacant, 
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
FROM portfolio_project..nashville_housing

-- 5.3 Updating column 

UPDATE portfolio_project..nashville_housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END

-- 6. Remove Duplicates

WITH RowNumCTE AS (
SELECT 
	*,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress, 
				SalePrice, 
				SaleDate, 
				LegalReference
				ORDER BY 
					UniqueID
					) row_num 
FROM portfolio_project..nashville_housing
)
DELETE
FROM RowNumCTE 
WHERE row_num >1

-- 7. Delete unused columns 

ALTER TABLE  portfolio_project..nashville_housing
DROP COLUMN
	OwnerAddress, 
	TaxDistrict, 
	PropertyAddress, 
	SaleDate

-- 8. Checking updated table 

SELECT * 
FROM portfolio_project..nashville_housing
ORDER BY UniqueID


