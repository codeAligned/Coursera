% You should put all your code for recognizing unknown actions in this file.
% Describe the method you used in YourMethod.txt.
% Don't forget to call SavePrediction() at the end with your predicted labels to save them for submission, then submit using submit.m
%EM_cluster
%RecognizeActions
function [predicted_labels] = RecognizeUnknownActions(datasetTrain, datasetTest, G, maxIter)

% INPUTS
% datasetTrain: dataset for training models, see PA for details
% datasetTest: dataset for testing models, see PA for details
% G: graph parameterization as explained in PA decription
% maxIter: max number of iterations to run for EM

% OUTPUTS
% accuracy: recognition accuracy, defined as (#correctly classified examples / #total examples)
% predicted_labels: N x 1 vector with the predicted labels for each of the instances in datasetTest, with N being the number of unknown test instances


% Train a model for each action
% Note that all actions share the same graph parameterization and number of max iterations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% YOUR CODE HERE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dim = [size(datasetTrain(1).poseData, 1), size(datasetTrain(2).poseData, 1), size(datasetTrain(3).poseData, 1)];
InitialClassProb4 = rand(sum(dim), 3);
InitialClassProb4 = InitialClassProb4 ./ repmat(sum(InitialClassProb4, 2), 1, 3);
%[PCluster loglikelihoodCluster ClassProbCluster] = EM_cluster(vertcat(datasetTrain(1).poseData, datasetTrain(2).poseData, datasetTrain(3).poseData), G, vertcat(datasetTrain(1).InitialClassProb, datasetTrain(2).InitialClassProb, datasetTrain(3).InitialClassProb), maxIter);
[PCluster loglikelihoodCluster ClassProbCluster] = EM_cluster(vertcat(datasetTrain(1).poseData, datasetTrain(2).poseData, datasetTrain(3).poseData), G, InitialClassProb4, maxIter);
%[P1Cluster loglikelihood1Cluster ClassProb1Cluster] = EM_cluster(datasetTrain(1).poseData, G, datasetTrain(1).InitialClassProb, maxIter);
%[P1 loglikelihood1 ClassProb1 PairProb1] = EM_HMM(datasetTrain(1).actionData, datasetTrain(1).poseData, G, datasetTrain(1).InitialClassProb, datasetTrain(1).InitialPairProb, maxIter);
%[P1 loglikelihood1 ClassProb1 PairProb1] = EM_HMM(datasetTrain(1).actionData, datasetTrain(1).poseData, G, ClassProb1Cluster, datasetTrain(1).InitialPairProb, maxIter);
[P1 loglikelihood1 ClassProb1 PairProb1] = EM_HMM(datasetTrain(1).actionData, datasetTrain(1).poseData, G, ClassProbCluster(1 : dim(1), :, :), datasetTrain(1).InitialPairProb, maxIter);
%[P2Cluster loglikelihood2Cluster ClassProb2Cluster] = EM_cluster(datasetTrain(2).poseData, G, datasetTrain(2).InitialClassProb, maxIter);
%[P2 loglikelihood2 ClassProb2 PairProb2] = EM_HMM(datasetTrain(2).actionData, datasetTrain(2).poseData, G, datasetTrain(2).InitialClassProb, datasetTrain(2).InitialPairProb, maxIter);
%[P2 loglikelihood2 ClassProb2 PairProb2] = EM_HMM(datasetTrain(2).actionData, datasetTrain(2).poseData, G, ClassProb2Cluster, datasetTrain(2).InitialPairProb, maxIter);
[P2 loglikelihood2 ClassProb2 PairProb2] = EM_HMM(datasetTrain(2).actionData, datasetTrain(2).poseData, G, ClassProbCluster(dim(1) + 1 : sum(dim(1 : 2)), :, :), datasetTrain(2).InitialPairProb, maxIter);
%[P3Cluster loglikelihood3Cluster ClassProb3Cluster] = EM_cluster(datasetTrain(3).poseData, G, datasetTrain(3).InitialClassProb, maxIter);
%[P3 loglikelihood3 ClassProb3 PairProb3] = EM_HMM(datasetTrain(3).actionData, datasetTrain(3).poseData, G, datasetTrain(3).InitialClassProb, datasetTrain(3).InitialPairProb, maxIter);
%[P3 loglikelihood3 ClassProb3 PairProb3] = EM_HMM(datasetTrain(3).actionData, datasetTrain(3).poseData, G, ClassProb3Cluster, datasetTrain(3).InitialPairProb, maxIter);
[P3 loglikelihood3 ClassProb3 PairProb3] = EM_HMM(datasetTrain(3).actionData, datasetTrain(3).poseData, G, ClassProbCluster(sum(dim(1 : 2)) + 1 : sum(dim), :, :), datasetTrain(3).InitialPairProb, maxIter);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Classify each of the instances in datasetTrain
% Compute and return the predicted labels and accuracy
% Accuracy is defined as (#correctly classified examples / #total examples)
% Note that all actions share the same graph parameterization

accuracy = 0;
predicted_labels = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% YOUR CODE HERE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
P = [P1, P2, P3];
N = size(datasetTest.poseData, 1);
K = size(datasetTest.poseData, 3);
L = size(datasetTest.actionData, 2);
loglikelihood = zeros(L, K);

for iclass = 1 : 3
  logEmissionProb = zeros(N, K);

  for i = 1 : N
    data = squeeze(datasetTest.poseData(i, :, :));
    for j = 1 : 10
      if G(j, 1) == 0
        for k = 1 : K
          logEmissionProb(i, k) += locallognormpdf(data(j, 1), P(iclass).clg(j).mu_y(k), P(iclass).clg(j).sigma_y(k));
          logEmissionProb(i, k) += locallognormpdf(data(j, 2), P(iclass).clg(j).mu_x(k), P(iclass).clg(j).sigma_x(k));
          logEmissionProb(i, k) += locallognormpdf(data(j, 3), P(iclass).clg(j).mu_angle(k), P(iclass).clg(j).sigma_angle(k));
        end
      else
        parent = data(G(j, 2), :);
        for k = 1 : K
          theta = P(iclass).clg(j).theta(k, :);
          mu_y = [1, parent] * theta(1 : 4)';
          mu_x = [1, parent] * theta(5 : 8)';
          mu_angle = [1, parent] * theta(9 : 12)';
          logEmissionProb(i, k) += locallognormpdf(data(j, 1), mu_y, P(iclass).clg(j).sigma_y(k));
          logEmissionProb(i, k) += locallognormpdf(data(j, 2), mu_x, P(iclass).clg(j).sigma_x(k));
          logEmissionProb(i, k) += locallognormpdf(data(j, 3), mu_angle, P(iclass).clg(j).sigma_angle(k));
        end
      end
    end
  end

  for i = 1 : L
    % construct factors with three types and do inference to fill ClassProb and PairProb
    m = length(datasetTest.actionData(i).marg_ind); % 1 to m represents S variables
    F = repmat(struct('var', [], 'card', [], 'val', []), 1, 2 * m);
    % 1 is inital probability P(S1)
    F(1).var = [1]; F(1).card = [K]; F(1).val = log(P(iclass).c);
    % 2~m is transition probability P(Si|Si-1)
    transMat = log(reshape(P(iclass).transMatrix', 1, K * K));
    for j = 2 : m
      F(j).var = [j, j - 1]; F(j).card = [K, K]; F(j).val = transMat;
    end
    % m+1~2*m is emission probability P(O|S) = P(Pose|State)
    for j = 1 : m
      F(m + j).var = [j]; F(m + j).card = [K];
      F(m + j).val = logEmissionProb(datasetTest.actionData(i).marg_ind(j), :);
    end
    % inference
    [M, PCalibrated] = ComputeExactMarginalsHMM(F);
    loglikelihood(i, iclass) = logsumexp(PCalibrated.cliqueList(1).val); % summation on any clique is OK
  end
end
[~, predicted_labels] = max(loglikelihood, [], 2);
%accuracy = sum(predicted_labels == datasetTest.labels) / L
SavePredictions(predicted_labels);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% call local lognormpdf for speeding up
function val = locallognormpdf(x, mu, sigma)
val = - (x - mu).^2 / (2*sigma^2) - log (sqrt(2*pi) * sigma);
end

