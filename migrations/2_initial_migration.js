const ProjectsFundraising = artifacts.require("ProjectsFundraising");

module.exports = function (deployer) {
  deployer.deploy(ProjectsFundraising);
};
