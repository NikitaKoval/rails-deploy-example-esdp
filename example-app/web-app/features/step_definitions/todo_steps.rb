When(/^пользователь находится на главной странице$/) do
  visit("/")
  sleep(2)
end

When(/^пользователь вводит новую задачу "([^"]*)"$/) do |todo_text|
  fill_in 'new-todo', :with => todo_text
  find('#new-todo').native.send_keys(:return)
  sleep(2)
end

When(/^пользователь видит задачу "([^"]*)" в списке$/) do |todo_text|
  expect(page).to have_xpath("//label[contains(text(), '#{todo_text}')]")
  sleep(2)
end