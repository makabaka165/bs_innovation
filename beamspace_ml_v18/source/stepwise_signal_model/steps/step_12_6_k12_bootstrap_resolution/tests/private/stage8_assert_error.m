function stage8_assert_error(callback, expected_identifier)
%STAGE8_ASSERT_ERROR Assert that a callback raises the registered error.

raised = false;
try
    callback();
catch exception
    raised = strcmp(exception.identifier, expected_identifier);
end
assert(raised, 'stage8_assert_error:MissingError', ...
    'Expected error %s was not raised.', expected_identifier);
end
