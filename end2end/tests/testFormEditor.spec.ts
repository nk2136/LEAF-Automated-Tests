import { test, expect } from '@playwright/test';

test.describe.configure({ mode: 'serial' });

// Generate unique text to help ensure that fields are being filled correctly.
let randNum = Math.random();
let uniqueText = `New Form ${randNum}`;

test('Create New Form', async ({ page }) => {
  await page.goto('https://host.docker.internal/Test_Request_Portal/admin/?a=form_vue#/');
  await page.getByRole('button', { name: 'Create Form' }).click();
  await page.getByLabel('Form Name (up to 50').fill('My New Form');
  await page.getByLabel('Form Name (up to 50').press('Tab');
  await page.getByLabel('Form Description (up to 255').fill('My New Form Description');
  await page.getByRole('button', { name: 'Save' }).click();
  await expect(page.getByLabel('Form name')).toHaveValue('My New Form');
  await expect(page.getByLabel('Form description')).toHaveValue('My New Form Description');
  await page.getByRole('link', { name: 'Form Browser' }).click();
  await expect(page.getByRole('link', { name: 'My New Form' })).toBeVisible();
});

test('Add Section to Form', async ({ page }) => {
  await page.goto('https://host.docker.internal/Test_Request_Portal/admin/?a=form_vue#/');
  await page.getByRole('link', { name: 'My New Form' }).click();
  await page.getByLabel('Add Section').click();
  await page.getByLabel('Section Heading').click();
  await page.getByLabel('Section Heading').fill(uniqueText + ' Section');
  await page.getByRole('button', { name: 'Save' }).click();
  await expect(page.getByLabel('Section Heading')).toHaveText(uniqueText + ' Section');
});

test('Add Question to Form', async ({ page }) => {
  await page.goto('https://host.docker.internal/Test_Request_Portal/admin/?a=form_vue#/');
  await page.getByRole('link', { name: 'My New Form' }).click();
  await page.getByLabel('Add Question to Section').click();
  await page.getByLabel('Field Name').click();
  await page.getByLabel('Field Name').fill('Are you a VA Employee?');
  await page.getByLabel('Short label for spreadsheet').click();
  await page.getByLabel('Short label for spreadsheet').fill('VA Employee?');
  await page.getByLabel('Input Format').selectOption('radio');
  await page.getByLabel('Options (One option per line)').click();
  await page.getByLabel('Options (One option per line)').fill('Yes\nNo');
  await page.getByRole('button', { name: 'Save' }).click();
  await expect(page.getByText('Are you a VA Employee?')).toBeVisible();
});

test('Add Sub-Question to Form', async ({ page }) => {
  await page.goto('https://host.docker.internal/Test_Request_Portal/admin/?a=form_vue#/');
  await page.getByRole('link', { name: 'My New Form' }).click();
  await page.getByLabel('add sub-question').click();
  await page.getByLabel('Field Name').fill('Supervisor Name');
  await page.getByLabel('Short label for spreadsheet').click();
  await page.getByLabel('Short label for spreadsheet').fill('Supervisor');
  await page.getByLabel('Input Format').selectOption('text');
  await page.getByRole('button', { name: 'Save' }).click();
  await expect(page.getByText('Supervisor Name')).toBeVisible();
});

test('Create Pre-Filled If/Then Question', async ({ page }) => {
  await page.goto('https://host.docker.internal/Test_Request_Portal/admin/?a=form_vue#/');
  await page.getByRole('link', { name: 'My New Form' }).click();
  await page.getByText('Modify Logic').last().click();
  await page.getByLabel('New Condition').click();
  await page.getByLabel('Select an outcome').selectOption('pre-fill');
  
  // Make selectOption more readable
  let optionToSelect = await page.locator('option', {hasText: 'Are you a VA Employee?'}).textContent();
  
  // remove trailing space
  const optionToSelectNoSpace = optionToSelect?.trim();
  await page.getByTitle('select controller question').selectOption({label: optionToSelectNoSpace});
  await page.getByLabel('select condition').selectOption('==');
  await page.getByLabel('select a value').selectOption('Yes');
  await page.getByLabel('Enter a pre-fill value').click();
  await page.getByLabel('Enter a pre-fill value').fill('Jane Doe');
  await page.getByText('Close').focus();
  await expect(page.locator('#condition_editor_inputs')).toContainText('THEN \'Supervisor Name\' will have the value \'Jane Doe\'');
  await page.getByRole('button', { name: 'Save' }).click();
  await expect(page.getByLabel('Conditions For Supervisor').getByRole('listitem')).toContainText('If \'Are you a VA Employee?\' is Yes then pre-fill this question.');
  await page.getByText('Close').click();
})

test('Delete Form', async ({ page }) => {
  await page.goto('https://host.docker.internal/Test_Request_Portal/admin/?a=form_vue#/');
  await page.getByRole('link', { name: 'My New Form' }).click();
  await expect(page.getByRole('heading', { name: 'Admin  Form Browser  Form' })).toBeVisible();
  await page.getByLabel('delete this form').click();
  await page.getByRole('button', { name: 'Yes' }).click();
  await expect(page.locator('#createFormButton')).toContainText('Create Form');
  await expect(page.getByRole('link', { name: 'My New Form' })).not.toBeVisible();
});





