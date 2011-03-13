% Run statistical test to verify if the input samples are generated by the
% Mean-reverting process.
% Inputs:-
% 
function [failed failed_test expected_moments observed_moments observed_alphas observed_model_parms] = meanRevertingTest(samples, model_parms, tolerence)

    % model parms - 2 alternative ways to define the OU model
    if (isfield(model_parms, 'drift') && isfield(model_parms, 'speed') && isfield(model_parms, 'sigma') && isfield(model_parms, 'T') && ~isfield(model_parms, 'mu') && ~isfield(model_parms, 'lambda') && ~isfield(model_parms, 'deltaT'))
        drift = model_parms.drift;
        speed = model_parms.speed;
        lambda = speed;
        mu = drift / speed;
        T = model_parms.T;
    elseif (isfield(model_parms, 'mu') && isfield(model_parms, 'lambda') && isfield(model_parms, 'sigma') && isfield(model_parms, 'deltaT') && isfield(model_parms, 'T') && ~isfield(model_parms, 'drift') && ~isfield(model_parms, 'speed'))
        mu = model_parms.mu;
        lambda = model_parms.lambda;
        sigma = model_parms.sigma;
        deltaT = model_parms.deltaT;
        T = model_parms.T;
    else
        error('bad input arguments');
    end
    
    failed_test.testA = zeros(1,3);
    failed_test.testB = zeros(5,3);
    failed_test.testC = zeros(1,2);
    
    [num_of_runs, num_of_samples_per_run] = size(samples);
    
    % A. Normality test on one run of the sequence increment only
    OUSims_i_minus_1 = samples(1,1:end-1);
    OUSims_i = samples(1,2:end);
    term3 = sigma * sqrt((1-exp(-2*lambda*deltaT))/(2*lambda));
    z = (OUSims_i - OUSims_i_minus_1 * exp(-lambda*deltaT) - mu*(1-exp(-lambda*deltaT))) ./ term3;
    standard_normal_moments = [0 1 0 3];    
    [failed ft stats] = normalityTests(z', standard_normal_moments');
    observed_moments(1,:) = stats.observed_moments;
    observed_alphas(1,:) = stats.observed_alphas;
    failed_test.testA = ft; 
    
    % B. Normality test on runs at 5 different moments in time
    t_step_size = floor(num_of_samples_per_run / 5);
    t_index = 2:t_step_size:num_of_samples_per_run;
    t = (t_index - 1) * deltaT;
    firsts = samples(1,1) .* exp(-lambda*t) + mu * (1 - exp(-lambda*t)); % expected value, all realizations start with the same init value
    seconds = sigma^2 / (2*lambda) * (1 - exp(-2*lambda*t)); % variance
    expected_moments_B = [firsts; seconds]; % only first two moments
    [f ft stats] = normalityTests(samples(:,t_index), expected_moments_B);
    observed_moments(2:length(t_index)+1,:) = stats.observed_moments;
    observed_alphas(2:length(t_index)+1,:) = stats.observed_alphas;
    failed = failed | f;
    failed_test.testB = ft;
    
    expected_moments = zeros(1+length(t_index),4);
    expected_moments(1,:) = standard_normal_moments;
    expected_moments(2:end,1:2) = expected_moments_B';
    expected_moments(2:end,3:end) = nan;

    % C. Model parameters estimation (on long term average, mu, and mean
    % reversion speed, lambda)
    % take average of 500 runs
    mu_vector = zeros(1,num_of_runs);
    sigma_vector = zeros(1,num_of_runs);
    lambda_vector = zeros(1,num_of_runs);    
    for i=1:num_of_runs
        [r, parms] = calcParmsNormalMeanReverting(samples(i,:)');
        mu_vector(i) = parms.drift / parms.speed;
        lambda_vector(i) = parms.speed;
        sigma_vector(i) = sqrt(parms.variance);
    end
    observed_model_parms.lambda = mean(lambda_vector);
    observed_model_parms.mu = mean(mu_vector);
    observed_model_parms.sigma = mean(sigma_vector); % sigma not tested
    mu_residual = abs(mu - observed_model_parms.mu);
    max_mu_error = tolerence * mu;
    f = (mu_residual > max_mu_error);
    ft = zeros(1,3);
    if (sum(f) > 0)
        failed = 1;
        ft(1) = 1;
    end
    lambda_residual = abs(lambda - observed_model_parms.lambda);
    max_lambda_error = tolerence * lambda;
    f = (lambda_residual > max_lambda_error);
    if (sum(f) > 0)
        failed = 1;
        ft(2) = 1;  
    end
    sigma_residual = abs(sigma - observed_model_parms.sigma);
    max_sigma_error = tolerence * sigma;
    f = (sigma_residual > max_sigma_error);
    if (sum(f) > 0)
        failed = 1;
        ft(3) = 1;  
    end    
    failed_test.testC = ft;
        
    % D. Simulated value plot against time
    r = round(rand(1,5) * (num_of_runs -1) + 1); % pick 5 random runs
    t_end = num_of_samples_per_run;
    i = 1:t_end;
    figure;
    plot(i,samples(r(1),:),i,samples(r(2),:),i,samples(r(3),:),i,samples(r(4),:),i,samples(r(5),:));
    title('Plot on 5 runs of simulated values');
    
end