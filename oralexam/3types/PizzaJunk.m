const Pizza <- typeobject Pizza
    operation getEaten
end Pizza

const JunkDeliverer <- typeobject JunkDeliverer
    operation Deliver -> [Any]
end JunkDeliverer

const PizzaDeliverer <- typeobject PizzaDeliverer
    operation Deliver -> [Pizza]
end PizzaDeliverer

% 1. Operations with same name.
% 2. Number of arguments and results.
% 3. Result types.
% 4. Argument types. (reversed)

% Pizza conforms to Any, but not vice versa.
